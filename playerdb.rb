# -*- coding: utf-8 -*-
#
#
#=== 変更履歴
#* 0.1 2013-10-07
#  * 新規作成
#

require "nokogiri"
require "open-uri"
require "json"

#
# 選手情報データベースクラス
#
class PlayerDB
  
  # 選手データベース (JSON形式)
  @@player_db = JSON.parse(open('playerdb.json').read)
  
  #
  # IDを指定して検索
  #
  def self.search(id)
    player = @@player_db[id]
    unless player then
      # playerがDBから検索出来なければ、Webから取得
      player = download(id)
      if player then
        @@player_db[id] = player
        # JSONファイルに保存
        JSON.dump(@@player_db, open('playerdb.json', 'w'))
      else
        return {}  # 空のハッシュを返す
      end
    end
    
    return player
  end
  
  
  #
  # IDを指定して削除
  #
  def self.delete(id)
    player =  @@player_db.delete(id)
    if player then
      JSON.dump(@@player_db, open('playerdb.json', 'w'))      
    end
    
    return player
  end
  
  
  #
  # IDを指定してWebから選手情報をダウンロード
  #
  def self.download (id)
    begin
      url = 'http://baseball.yahoo.co.jp/npb/player?id=' + id
      doc = Nokogiri::HTML(open(url))
    rescue OpenURI::HTTPError => ex
      warn ex.message
      return nil
    end
    
    player_div = doc.xpath('//div[@class="PlayerAdBox mb15"]')

    # チーム
    team = /NpbTeamLogoTop (.+)/.match(player_div.css('a').attribute('class').text)[1]
    # 名前、背番号、ポジション
    h1 = player_div.xpath('.//h1').children
    name = h1[0].text.gsub('　', "")
    h1[1].text.gsub('　', "") =~ /（(.+)）/
    p reading = $1
    number = h1[2].text
    position = h1[3].text
    
    player_trs = player_div.xpath('./div[@class="yjS"]//tr')
    
    # 誕生日、年齢、出身地
    player_trs[0].xpath('./td')[1].text =~ /([0-9]+)年([0-9]+)月([0-9]+)日（([0-9]+)歳）/
    birthday = [$1.to_i, $2.to_i, $3.to_i]
    age = $4.to_i
    birthplace = player_trs[0].xpath('./td')[2].text
    
    # 身長、体重、血液型、投、打
    player_trs[1].xpath('./td')[0].text =~ /([0-9]+)cm\/([0-9]+)kg（(.+)）/
    height = $1.to_i
    weight = $2.to_i
    bloodtype = $3
    player_trs[1].xpath('./td')[1].text =~ /(.)投げ(.)打ち/
    throws = $1
    bats = $2
    
    # 経験年数、ドラフト
    player_trs[2].xpath('./td')[1].text =~ /([0-9]+)年/
    experience = $1.to_i
    draft = player_trs[2].xpath('./td')[0].text
    
    # 経歴
    career = player_trs[3].xpath('./td')[0].text.split('－')
    
    # 獲得タイトル
    title = player_trs[4].xpath('./td')[0].text.scan(/'（(.)）([0-9]{2}+)'/)
    
    # コメント
    comment = player_trs[5].xpath('./td')[0].text
    
    # 選手情報
    player = {:name => name, :reading => reading,
      :team => team, :number => number, :position => position,
      :birthday => birthday, :age => age, :birthplace => birthplace,
      :height => height, :weight => weight, :bloodtype => bloodtype,
      :throws => throws, :bats => bats,
      :draft => draft, :experience => experience, :career => career,
      :title => title, :comment => comment}
    return player
  end
  
end
  
