#!/usr/bin/env ruby
require 'nokogiri'
require 'json'
require 'curb'

MT_URL = 'https://ct.cloudflare.com'

c = Curl::Easy.new(MT_URL)
c.perform

h = Nokogiri::HTML(c.body_str)

preload_str = h.at_css('script').inner_text.strip
preload_str.gsub!(/^var\s+preload\s*=\s*/,'')

preload = JSON.parse(preload_str)
breakdown = preload['/index']['Breakdown']

# Values are a hash, with 'U' for unexpired count, 'E' for expired count
# Keys are in the format 'w:x:y:z:Name'
# w = Entry Type 1: precert, 2: cert, 3: ct-qual cert
# x = Signature Algorithm 0: other, 1:, 2:, 3: RSA SHA-1, 4:, 5:, 6:, 8:, 9:, 10: 11:, 12:, 13:
# y = Public Key Algorithm 0: other, 1: RSA, 2: DSA, 3: ECDSA 
# z = Validation Level 0: other, 1: domain, 2: org, 3: ev
# Name is a string of the CA

K = [:type, :sig, :pubkey, :vallvl, :name]

data = {}
breakdown.each do |k, v|
  i = Hash[K.zip(k.split(':'))]
  data[i] = v
end

total = data.select do |k, v|
  k[:name] =~ /Entrust|Affirm/i
end.map do |k, v|
  v['U']
end.reduce(:+)

pp total
