#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#require "open-uri"
#require "rubygems"
require "json"
require "nokogiri"


## 投手情報を取得
def pitcher_info (doc)
  detail = doc.xpath('//div[@id="deC"]')
  players = detail.xpath('//div[@class="clearfix"]/div[@class="kyusyu"]/p')

  # 投手
  info = players[0].text.scan(/投手：(.+)（(.)）/)[0]
  name = info[0]
  hand = info[1]

  id = /http:\/\/baseball.yahoo.co.jp\/npb\/player\?id=([0-9]+)/.match(players[0].xpath('a')[0]['href'])[1]

  return {'name' => name, 'hand' => hand, 'id' => id}
end


## 打者情報を取得
def batter_info (doc)
  detail = doc.xpath('//div[@id="deC"]')
  players = detail.xpath('//div[@class="clearfix"]/div[@class="kyusyu"]/p')

  # 打者
  info = players[2].text.scan(/打者：(.+)（(.)）/)[0]
  name = info[0]
  hand = info[1]
  
  id = /http:\/\/baseball.yahoo.co.jp\/npb\/player\?id=([0-9]+)/.match(players[2].xpath('a')[0]['href'])[1]

  return {'name' => name, 'hand' => hand, 'id' => id}
end


## 左上(0, 0) 5x5の投球コーステーブルを作成
## 0 < x < 4 && 0 < y < 4 でストライク
## +-----+-----+-----+-----+-----+
## |(0,0)|     |     |     |(4,0)|
## |     |     |     |     |     |
## +-----+=====+=====+=====+-----+
## |     ||    |     |    ||     |
## |     ||    |     |    ||     |
## +-----+-----+-----+-----+-----+
## |     ||    |(2,2)|    ||     |
## |     ||    |     |    ||     |
## +-----+-----+-----+-----+-----+
## |     ||    |     |    ||     |
## |     ||    |     |    ||     |
## +-----+=====+=====+=====+-----+
## |(0,4)|     |     |     |(4,4)|
## |     |     |     |     |     |
## +-----+-----+-----+-----+-----+
def make_course_table (doc)
  detail = doc.xpath('//div[@id="deC"]')
  course_table = detail.xpath('//div[@class="kyusyu-mark"]/table/tbody/tr').map do |column|
    column.xpath('td').map do |row|
      #row.text.gsub("\n", "")
      row.text.split("\n")
    end
  end
  
  return course_table
end


## コースの検索
def search_course (table, mark)
  table.each_with_index do |col, y|
    col.each_with_index do |course, x|
      return [x, y] if course.index(mark) # 左上を(0, 0)にした5x5のコースを返す
    end
  end
  
  return nil
end


## 投球情報からハッシュを作成
def pitch_info (pitch, course_table)
  total = pitch[1].to_i                                         # 総投球数
  mark = pitch[0]                                               # 記号
  no = /.+([0-9]+)/.match(pitch[0])[1].to_i                     # 投球
  type = pitch[2]                                               # 球種
  speed = pitch[3].gsub("km/h", "").to_i                        # 球速
  result = /([^\[\]]+)/.match(pitch[4])[0]                      # 結果
  comment = pitch[4].scan(/\[\s*(\S+)\s*\]/).map { |c| c[0] }   # 備考
  bso = pitch[5].gsub(" ", "")                                  # カウント
  b = bso[0].to_i
  s = bso[1].to_i
  o = bso[2].to_i

  course = search_course(course_table, mark)
  
  return {'total' => total, 'no' => no, 'mark' => mark, 'type' => type,
    'speed' => speed, 'course' => course, 'result' => result,
    'comment' => comment, 'bso' => {'b' => b, 's' => s, 'o' => o}}
end


## 打席情報を作成
def turn_info (doc)
  # コース情報テーブルを作成
  course_table = make_course_table(doc)
  
  # 投球を配列で抽出
  detail = doc.xpath('//div[@id="deC"]')
  # 先頭はヘッダなので読み込まない
  pitches = detail.xpath('//div[@class="text mb20p clearfix"]/table/tbody/tr')[1..-1].map do |column|
    column.xpath('td').map { |row| row.text }
  end
  
  # 打席の全投球情報
  pitches_info = pitches.map { |pitch| pitch_info(pitch, course_table) }
  
  # 打者・投手情報
  batter_info = batter_info(doc)
  pitcher_info = pitcher_info(doc)
  
  turn_info = {'batter' => batter_info, 'pitcher' => pitcher_info,
    'pitches' => pitches_info}
  
  return turn_info
end



html_name = ARGV[0]
doc = Nokogiri::HTML.parse(open(html_name))

puts JSON.pretty_generate(turn_info = turn_info(doc))
