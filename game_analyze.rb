#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#require "open-uri"
#require "rubygems"
require "json"
require "nokogiri"


$position_table = {
  投: "P", 遊: "SS", 二: "2B", 左: "LF", 三: "3B",
  捕: "C", 一: "1B", 右: "RF", 中: "CF"}


$team_table = {
  G:  "読売ジャイアンツ",
  T:  "阪神タイガース",
  C:  "広島東洋カープ",
  D:  "中日ドラゴンズ",
  DB: "横浜DeNAベイスターズ",
  S:  "東京ヤクルトスワローズ",
  
  E:  "東北楽天ゴールデンイーグルス",
  L:  "埼玉西武ライオンズ",
  M:  "千葉ロッテマリーンズ",
  H:  "福岡ソフトバンクホークス",
  Bs: "オリックス・バファローズ",
  F:  "北海道日本ハムファイターズ"}

$tb_table = {表: "T", 裏: "B"}

$hr_table = {"ソロ" => "1R", "2ラン" => "2R", "3ラン" => "3R", "満塁" => "4R"}


## 試合情報のデータ抽出
def make_game_info (doc)
  # チーム名(記号)を取得
  teams = doc.xpath('//div[@class="AtDf"]/div[@class]')
  home_team = teams[0].attribute('class').value.split(' ')[1]
  visitor_team = teams[1].attribute('class').value.split(' ')[1]

  # スタジアム情報、開始時間を取得
  stadium = doc.xpath('//p[@class="stadium"]')[0].text.split("\n")[1]
  start_time = doc.xpath('//p[@class="stadium"]')[0].text.split("\n")[2]

  return {"team" => [home_team, visitor_team],
    "stadium" => stadium, "time" => start_time}
end


## 試合結果のデータ抽出
def make_result_info (doc)
  # スコアの抽出
  teamscore = doc.xpath('//div[@class="teamscore"]')
  home_score = teamscore.xpath('//em[@class="score"]')[0].text.to_i
  visitor_score = teamscore.xpath('//em[@class="score"]')[1].text.to_i

  # 試合時間と観客数の抽出
  detaildata = doc.xpath('//div[@id="yjSNLiveDetaildata"]//tr/td')
  attendance = detaildata[0].text[0..-2].to_i
  game_time = detaildata[1].text.scan(/([0-9]+)時間([0-9]+)分/)[0].join(":")

  return {"score" => [home_score, visitor_score],
    "attendance" => attendance, "time" => game_time}
end


## リンクから選手IDを取得
def scrape_player_id (link)
  link =~ /\/npb\/player\?id=([0-9]+)/
  return $1
end


## 先発投手のデータ抽出
def make_pitcher_info (pitcher_tr)
  tds = pitcher_tr.xpath('./td')

  name = tds[2].text.gsub('　', "")
  id = scrape_player_id(tds[2].xpath('./a').attribute('href').text)
  era = tds[4].text.to_f
  pitcher_info = {'name' => name, 'id' => id, 'era' => era}

  return pitcher_info
end


## 先発野手のデータ抽出
def make_bench_pitcher_info(pitcher_tr)
  tds = pitcher_tr.xpath('./td')
  
  name = tds[0].text.gsub('　', "")
  id = scrape_player_id(tds[0].xpath('./a').attribute('href').text)
  era = tds[2].text.to_f
  pitcher_info = {'name' => name, 'id' => id, 'era' => era}
  
  return pitcher_info
end  


## 控え投手のデータ抽出
def make_fielder_info (fielder_tr)
  tds = fielder_tr.xpath('./td')
  
  no = tds[0].text.to_i
  position = tds[1].text.scan(/（(.)）/)[0][0]
  name = tds[2].text.gsub('　', "")
  id = scrape_player_id(tds[2].xpath('./a').attribute('href').text)
  avg = tds[4].text.to_f
  fielder_info = {'no' => no, 'position' => position, 'name' => name,
    'id' => id, 'avg' => avg}
  
  return fielder_info
end


## 控え野手のデータ抽出
def make_bench_fielder_info (fielder_tr)
  tds = fielder_tr.xpath('./td')
  
  name = tds[0].text.gsub('　', "")
  id = scrape_player_id(tds[0].xpath('./a').attribute('href').text)
  avg = tds[2].text.to_f
  fielder_info = {'name' => name, 'id' => id, 'avg' => avg}
  
  return fielder_info
end


## 出場選手の抽出(ホーム)
def make_home_member_info (doc)

  # 先発選手の抽出
  starter_table = doc.xpath('//div[@id="yjSNLiveStartingmember"]/div[@class="column-left"]/table')

  # 先発投手の抽出
  starter_pitcher_tr = starter_table[0].xpath('./tr')[2]
  starter_pitcher = make_pitcher_info(starter_pitcher_tr)
  
  # 先発野手の抽出
  starter_fielder_tr = starter_table[1].xpath('./tr')[2..-1]
  starter_fielder = starter_fielder_tr.map { |tr| make_fielder_info(tr) }
  
  # ベンチ選手の抽出
  bench_trs = doc.xpath('//div[@id="yjSNLiveBenchmember"]/div[@class="column-left"]/table//tr')
  # <td>を抽出して、sizeが"3"の場合は投手、"4"の場合は野手という判定で分類
  bench_pitcher_trs = bench_trs.select { |tr| tr.xpath('./td').size == 3 }
  bench_pitcher = bench_pitcher_trs.map { |tr| make_bench_pitcher_info(tr) }
  
  bench_fielder_trs = bench_trs.select { |tr| tr.xpath('./td').size == 4 }
  bench_fielder = bench_fielder_trs.map { |tr| make_bench_fielder_info(tr) }

  member = {
    'starter' => {'pitcher' => starter_pitcher, 'fielder' => starter_fielder},
    'bench' => {'pitcher' => bench_pitcher, 'fielder' => bench_fielder}}
  
  return member
end


## 出場選手の抽出(ビジター)
def make_visitor_member_info (doc)

  # 先発選手の抽出
  starter_table = doc.xpath('//div[@id="yjSNLiveStartingmember"]/div[@class="column-right"]/table')

  # 先発投手の抽出
  starter_pitcher_tr = starter_table[0].xpath('./tr')[2]
  starter_pitcher = make_pitcher_info(starter_pitcher_tr)
  
  # 先発野手の抽出
  starter_fielder_tr = starter_table[1].xpath('./tr')[2..-1]
  starter_fielder = starter_fielder_tr.map { |tr| make_fielder_info(tr) }
  
  # ベンチ選手の抽出
  bench_trs = doc.xpath('//div[@id="yjSNLiveBenchmember"]/div[@class="column-right"]/table//tr')
  # <td>を抽出して、sizeが"3"の場合は投手、"4"の場合は野手という判定で分類
  bench_pitcher_trs = bench_trs.select { |tr| tr.xpath('./td').size == 3 }
  bench_pitcher = bench_pitcher_trs.map { |tr| make_bench_pitcher_info(tr) }
  
  bench_fielder_trs = bench_trs.select { |tr| tr.xpath('./td').size == 4 }
  bench_fielder = bench_fielder_trs.map { |tr| make_bench_fielder_info(tr) }

  member = {
    'starter' => {'pitcher' => starter_pitcher, 'fielder' => starter_fielder},
    'bench' => {'pitcher' => bench_pitcher, 'fielder' => bench_fielder}}
  
  return member
end



# 球審・塁審データの抽出
def make_judge_info (doc)
  judge_table = {
    "球審" => "PU", "塁審（一）" => "1BU",
    "塁審（ニ）" => "2BU", "塁審（三）" => "3BU"
  }
  
  judge_tr = doc.xpath('//div[@id="yjSNLiveJudge"]/table/tr')
  
#  position = judge_tr.xpath('./th').map {|th| judge_table[th.text]}
  name     = judge_tr.xpath('./td').map {|td| td.text}

#  judge = position.map.with_index do |pos, idx|
#    {"position" => pos, "name" => name[idx]}
#  end
  
#  return judge
  return {
    "pu" => name[0], "1bu" => name[1],
    "2bu" => name[2], "3bu" => name[3]
  }
end


# 試合記録（責任投手・本塁打）の取得
# game['record']['winning']['name']    勝ち投手名
# game['record']['losing']['id']       負け投手ID
# game['record']['HR'][1]['id']        本塁打2本目の打者ID
#
def make_record_info (doc)
  record_tr = doc.xpath('//div[@id="yjSNLivePitcher"]/table/tr')

  
  return {
    win: make_pitcher_record(record_tr[0]),
    lose: make_pitcher_record(record_tr[1]),
    save: make_pitcher_record(record_tr[2]),
    hr: make_batter_record_info(record_tr[3], record_tr[4])
  }
end

# 投手記録（責任投手）の取得
def make_pitcher_record (tr)

  info = tr.xpath('./td').text
  
  unless info.empty?
    a = tr.xpath('./td/p/a')
    name = a.text
    id   = scrape_player_id(a.attribute('href').text)
    return {name: name, id: id}
  end
end


# 打者記録（本塁打）の取得
def make_batter_record_info(visitor_tr, home_tr)

  visitor_team_hr = visitor_tr.xpath('./td/p').text.scan(/([^\n|、]+) ([0-9]+)号\(([0-9]+)回([表|裏])(.+)\)/).map.with_index do |hr, index|
    {
      name: hr[0],
      no: hr[1],
      #inning: hr[2] + $tb_table[hr[3]],
      type: $hr_table[hr[4]]
    }
  end
  visitor_team_hr.each do |hash|
    hash.store('id', scrape_player_id(visitor_tr.xpath('./td/p/a').attribute('href').text))
  end
  p visitor_team_hr
  
  
  home_team_hr = home_tr.xpath('./td/p').text.scan(/([^\n|、]+) ([0-9]+)号\(([0-9]+)回([表|裏])(.+)\)/).map.with_index do |hr, index|
    {
      name: hr[0],
      no: hr[1],
      #inning: hr[2] + $tb_table[hr[3]],
      type: $hr_table[hr[4]]
    }
  end
  home_team_hr.each do |hash|
    hash.store('id', scrape_player_id(home_tr.xpath('./td/p/a').attribute('href').text))
  end
  p home_team_hr

  return  [visitor_team_hr, home_team_hr].flatten
end



html_name = ARGV[0]
doc = Nokogiri::HTML.parse(open(html_name))

info = {
  game: make_game_info(doc), result: make_result_info(doc),
  team: [make_home_member_info(doc), make_visitor_member_info(doc)],
  judge: make_judge_info(doc), record: make_record_info(doc)
}

puts JSON.pretty_generate(info)
