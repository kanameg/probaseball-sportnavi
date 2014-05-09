#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#require "open-uri"
#require "rubygems"
require "json"
require "nokogiri"

## 指定日の各選手の打撃成績を取得
def date_bats_result (dir, date)
  Dir.chdir(dir)
  # ファイル名の取得．ブロック構文で，とりあえずファイル名の表示を行うことにする
  stats = Dir.glob("stats_" + date + "*.html").inject ({}) do |result, f|
    doc = Nokogiri::HTML.parse(open(f))
    result.merge(game_bats_result(doc))
  end

  {date => stats}
end


## 試合での打撃結果成績
def game_bats_result (doc)
  doc.xpath('//table[@class="yjS"]').inject({}) { |result, team|
    result.merge(team_bats_result(team))
  }
end


## チームでの打撃成績を取得
def team_bats_result (team_table)
  # 打撃結果 ※0行目と最終行はヘッダとフッタなので除く
  team_table.xpath('./tr')[1..-2].inject({}) { |result, tr|
    id, stats = bats_stats(tr)
    result[id] = stats
    result
  }
end


## 各個人の打撃成績を取得
def bats_stats (bats_tr)
  name = bats_tr.xpath('./td[@class="pn"]/a').text.gsub("　", "")   # 名前
  id = player_id(bats_tr.xpath('./td[@class="pn"]/a').attribute('href').text) # ID

  stats_tds = bats_tr.xpath('./td')[2..12]
  # 打率
  avg = avg == ".---" ? ".000".to_f : stats_tds[0].text.to_f
  
  # 打数
  ab = stats_tds[1].text.to_i

  # 安打数
  hit = stats_tds[3].text.to_i
  
  # 打点
  rbi = stats_tds[4].text.to_i

  # 三振
  so = stats_tds[5].text.to_i

  # 四死球
  walk = stats_tds[6].text.to_i

  # 犠打
  sh = stats_tds[7].text.to_i

  # 盗塁
  sb = stats_tds[8].text.to_i

  # 失策
  e = stats_tds[9].text.to_i

  # 本塁打
  hr = stats_tds[10].text.to_i 

  # 打席結果
  inning_tds = bats_tr.xpath('./td')[13..-1]
  bats = inning_tds.map { |td|
    td.children.reject { |elm| elm.name == 'br'}.map { |elm|
      is_hit = hit?(elm)
      is_run = run?(elm)
      result = elm.text
      {is_hit: is_hit, is_run: is_run, result: result}
    }
  }
  
  return id, {name: name, avg: avg, ab: ab, hit: hit, rbi: rbi, so: so, walk: walk, sh: sh, sb: sb, e: e, hr: hr, bats: bats}
end


## リンクから選手IDを取得
def player_id (link)
  link =~ /\/npb\/player\?id=([0-9]+)/
  return $1
end


## ヒットの確認
def hit? (elm)
  if elm.attribute("class")
    if elm.attribute("class").value == "red"
      return true
    end
  end
  
  return false
end


## 得点の確認
def run? (elm)
  if elm.name == "b"
    return true
  end
  
  return false
end


date = ARGV[0]
p date_bats_result("./data", date)
#puts JSON.pretty_generate(date_bats_result("./data", date))



