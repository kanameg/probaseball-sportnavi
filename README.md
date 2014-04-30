# SportNavi プロ野球一球速報解析

SportNavi(Yahooプロ野球)の一球速報データを解析して統計データを取るための解析ツール

取得するデータは以下
* 試合データ
    * 対戦カード（回戦数） ☆
    * 球場 ☆
    * 開始時間 ☆
    * 試合時間 ☆
    * 観衆数 ☆
    * 試合概要、戦評 ☆
    * 勝投手、負投手、セーブ [勝ち数、負け数、セーブ数] △
    * 本塁打打者 
    * 得点（試合） ☆
    * 得点（イニング別） 
    * スタメン（投手[防御率]、野手[ポジション、打順、打率]） ※試合開始時 ☆
    * 控え選手（投手[防御率]、内野手[打率]、外野手[打率]） ※試合開始時 ☆
    * 審判（球審、塁審） ☆
    
* 投球データ
    * 対戦投手と打者 ☆
    * 球種 ☆
    * 球速 ☆
    * コース ☆
    * 結果 ☆
    * カウント ☆
    * 投球数 ☆
    
* 打撃データ
    * (未実装)
    
* 選手データ
    * (未実装)



## データ構造
### 試合情報データ構造
* 日付 ['YYYY-MM-DD']
    * 試合INDEC ['GG']
        * 試合情報 ['game']
            * チーム ['team'][2]    ※ 0: ホームチーム 1: ビジターチーム
            * 球場 ['stadium']
            * 開始時間 ['time']     ※ HH:MM形式
            
        * 試合結果情報 ['result']
            * スコアー ['score'][2] ※ 0: ホームチーム 1: ビジターチーム
            * 観客数 ['attendance']
            * 試合時間 ['time']     ※ HH:MM形式
            * 記録情報 ['record']
                * 勝ち投手 ['win']
                    * 名前 ['name']
                    * ID ['id']
                    * 記録(試合終了時) ['record'] 未実装
                * 負け投手 ['lose']
                    * 名前 ['name']
                    * ID ['id']
                    * 記録(試合終了時) ['record'] 未実装
                * 抑え投手 ['save']
                    * 名前 ['name']
                    * ID ['id']
                    * 記録(試合終了時) ['record'] 未実装
                * 本塁打 ['hr'][]
                    * 名前 ['name']
                    * ID ['id']
                    * 本数(打撃時) ['no']
                    * イニング ['inning'] 未実装
                    * 種類 ['type']   ※ ソロ,2ラン,3ラン,満塁

        * メンバー情報 ['member']
            * 先発メンバー ['starter']
                * 投手 ['pitcher']
                * 野手 ['fielder'][9]  ※ 基本打順順
                    * 打順(試合開始時) ['no']
                    * 守備位置(試合開始時) ['position']
                    * 名前 ['name']
                    * ID ['id']
                    * 打率(試合開始時) ['avg']
            * 控えメンバー ['bench']
                * 投手 ['pitcher'][]
                    * 名前 ['name']
                    * ID ['id']
                    * 防御率(試合開始時) ['era']
                * 野手 ['fielder'][]
                    * 名前 ['name']
                    * ID ['id']
                    * 打率(試合開始時) ['avg']
            * 審判 ['umpier'][4]     ※ 基本 球審(pu),1塁塁審(1bu),2塁塁審(2bu),3塁塁審(3bu)の順
                * 位置 ['position']  ※ pu,1bu,2bu,3bu
                * 名前 ['name']


### 打撃結果データ構造
* 日付 ['YYYY-MM-DD']
    * 試合INDEC ['GG']
        * 打撃結果 ['batting'][]
            * 守備位置 ['position']
            * ID ['id']
            * 名前 ['name']   ※姓名形式
            * 打率(試合終了時点) ['avg']
            * 打数 ['ab']
            * 得点 ['run']
            * 安打 ['hit']
            * 打点 ['rbi']
            * 三振 ['so']
            * 四死球 ['bb']
            * 犠打 ['sh']
            * 盗塁 ['sb']
            * 本塁打 ['hr']
            * 打撃結果 ['bat'][]   ※ 打席順
                * イニング ['inning']
                * 結果 ['result']
                * 打点 ['isrun']    ※ True or False
                * 安打 ['ishit']    ※ True or False

### 投球結果データ構造
* 日付 ['YYYY-MM-DD']
    * 試合INDEC ['GG']
        * 投球結果 ['pitching'][]



## 英語用語 略語
|            | 英語                       | 英略字 |
|:-----------|:---------------------------|:------:|
| 打席       | at bat                     | AB     |
| 安打       | hit                        | H 1B   |
| 二塁打     | double                     | 2B     |
| 三塁打     | triple                     | 3B     |
| 本塁打     | home run                   | HR     |
| 四球       | base on balls              | BB     |
| 敬遠       | intentional base on balls  | IBB    |
| 死球       | hit by pitch               | HBP    |
| 犠打       | sacrifice hit              | SH     |
| 犠飛       | sacrifice fly              | SF     |
| 盗塁       | stolen base                | SB     |
| ゴロ       | grounded out               | GO     |
| フライ     | flied out                  | FO     |
| 三振       | strike out                 | SO     |
| 野選       | fielders choice            | FC     |
| エラー     | error                      | E      |



## 打席結果
### 打球方向
| カタカナ      | 漢字     | 番号 | 略字 | 
|:-------------:|:--------:|:----:|:----:|
| ピッチャー    | 投手     | 1    | 投   |
| キャッチャー  | 捕手     | 2    | 捕   |
| ファースト    | 一塁手   | 3    | 一   |
| セカンド      | 二塁手   | 4    | ニ   |
| サード        | 三塁手   | 5    | 三   |
| ショート      | 遊撃手   | 6    | 遊   |
| レフト        | 左翼手   | 7    | 左   |
| センター      | 中堅手   | 8    | 中   |
| ライト        | 右翼手   | 9    | 右   |

### 安打
|                    |          | 略字 |
|:------------------:|:--------:|:----:|
| シングルヒット     | 安打     | 安   |
| ツーベースヒット   | 二塁打   | 二   |
| スリーベースヒット | 三塁打   | 三   |
| ホームラン         | 本塁打   | 本   |

### アウト
|                    |          | 略字 |
|:------------------:|:--------:|:----:|
| ゴロアウト         | ゴロ     | ゴ   |
| ライナーアウト     | ライナー | 直   |
| フライアウト       | フライ   | 飛   |

### 特殊打席 (アウト)
|                               | 略字 |
|:-----------------------------:|:----:|
| 送りバント                    | 犠打 |
| 犠牲フライ                    | 犠打 |

### 特殊打席 (出塁)
|                               | 略字 |
|:-----------------------------:|:----:|
| 相手のエラー                  | 敵失 |
| フィルダースチョイス          | 野選 |
| 守備妨害                      | 守妨 |
| 振り逃げ                      | 振逃 |
| ワイルドピッチ                | 暴投 |
| パスボール                    | 捕逸 |


### 特殊アウト
|                               | 略字 |
|:-----------------------------:|:----:|
| ファールフライ                | 邪飛 |
| ダブルプレー                  | 併殺 |
| トリプルプレー                | 三重 |






	