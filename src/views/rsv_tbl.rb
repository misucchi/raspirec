#!/usr/local/bin/ruby 
# -*- coding: utf-8 -*-

#
#  予約状況表
#


class RsvTbl

  Base = "/rsv_tbl"
  
  def initialize( date = nil, time = nil)

    @time = nil                 # カレント時間
    if date != nil and time != nil
      if date =~ /(\d+)-(\d+)-(\d+)/
        y = $1.to_i
        m = $2.to_i
        d = $3.to_i
        h = time.to_i
        @time = Time.local( y,m,d,h)
      end
    end
    if @time == nil
      ta = (Time.now - 3600 ).to_a
      @time = Time.local( ta[5],ta[4],ta[3],ta[2]) 
    end

    @tate = 24                  # 縦の長さ (H)
    @hour_pixel = 60            # 1時間の長さ (px)
    @maxnum = { Const::GR   => GR_tuner_num, # 横軸の数
                Const::BSCS => BSCS_tuner_num,
              }
    @st = @time.to_i             # start time
    @et = @st + @tate * 3600     # end time
    
    @rsvData = getPrgData( @st, @et )

  end

  #
  #  現在時間を示す線
  #
  def nowLine()

    stationN = @maxnum[ Const::GR ] + @maxnum[ Const::BSCS ]
    stationW = 160 + 2
    
    Commlib::nowLine( Time.at(@st), @tate, @hour_pixel, stationN, stationW, -10 )
  end

  
  #
  #  番組データの取得
  #
  def getPrgData( st, et )

    programs = DBprograms.new
    reserve = DBreserve.new
    rsvData = {}
    DBaccess.new().open do |db|
      row = reserve.selectSP(db, tstart: st, tend: et)
      row.each do |r|
        next if r[:stat] == RsvConst::NotUse
        next if r[:stat] == RsvConst::RecStop2
        band = r[:band] == Const::GR ? Const::GR : Const::BSCS
        tunerNum = r[:tunerNum] == nil ? 0 : r[:tunerNum]
        @maxnum[ band ] = tunerNum if @maxnum[ band ] < tunerNum
        tunerNum -= 1
        row2 = programs.select(db,chid: r[:chid], evid: r[:evid] )
        r[:prog] = row2.first
        rsvData[ band ] ||= {}
        rsvData[ band ][ tunerNum ] ||= []
        rsvData[ band ][ tunerNum ] << r
      end
    end

    rsvData
  end

  #
  #    時間指定の生成
  #
  def getTimeHref()
    ymd = @time.strftime("%Y-%m-%d")
    r = []
    r << sprintf("%s/%s/%02d",Base,ymd, 5 )
    r << sprintf("%s/%s/%02d",Base,ymd, 11 )
    r << sprintf("%s/%s/%02d",Base,ymd, 17 )
    r << sprintf("%s/%s/%02d",Base,ymd, 23 )
    t = @time - 3600 * 3 
    r << sprintf("%s/%s",Base, t.strftime("%Y-%m-%d/%H"))
    t =  @time + 3600 * 3 
    r << sprintf("%s/%s",Base, t.strftime("%Y-%m-%d/%H"))
    r
  end
  
  
  #
  # 日付指定の Badges in Dropdown
  #
  def dateSel()
    dow = Const::Wday
    now = Time.now
    tmp = []
    target = @time.strftime("%Y-%m-%d ") + dow[ @time.wday ]
    8.times do |n|
      t = now.strftime("%Y/%m/%d ") + dow[ now.wday ]
      href = sprintf("%s/%s/%s",
                     Base,
                     now.strftime("%Y-%m-%d"),
                     @time.strftime("%H") )
      tmp << [ t, href ]
      now += 3600 * 24
    end

    r = []
    t = @day
    r << %Q{<a class='dropdown-trigger btn col s2' data-target='dropdown1' href='#'> #{target}</a>}
    r << %Q{<ul class='dropdown-content' id='dropdown1'>}
    tmp.each do |tmp2|
      r << %Q{   <li> <a href='#{tmp2[1]}'>#{tmp2[0]}</a> </li>}
    end
    r << %Q{</ul>}
    r.join("\n")
  end

  #
  #  縦軸(時間)の生成
  #
  def tatejiku()
    t = @time
    r = []
    @tate.times.each  do |n|
      height = @hour_pixel - 4
      height += 3 if n == 0
      adj = "style=height:#{height}px;"
      r << sprintf(%Q{<div class='time' %s> %s </div>},adj, t.strftime("%H"))
      t += 3600
    end
    r.join("\n")
  end

  #
  #  横軸(チューナー)の生成
  #
  def yokojiku()
    r = []
    @maxnum[ Const::GR ].times do |n|
      r << sprintf(%Q{<div class='station'> GR-%s </div>},n+1)
    end
    @maxnum[ Const::BSCS ].times do |n|
      r << sprintf(%Q{<div class='station'> BSCS-%s </div>},n+1)
    end
    r.join("\n")
  end

  def printItem( time, text, cls: nil, rid: nil, tip: nil )
    px = ((( time ).to_f / 3600 ) *  @hour_pixel ).to_i
    style = sprintf(%Q{style="height:%dpx;" },px)
    cls2 = cls != nil ? %Q{class='#{cls.join(" ")}'} : ""
    tip2 = tip != nil ? %Q{data-tooltip="#{tip}"} : ""
    rid2 = rid != nil ? %Q{rid="#{rid}"} : ""

    sprintf(%Q{  <div %s %s %s %s> %s </div>},cls2, rid2,tip2,style, text )
  end
  
  #
  #  表
  #
  def prgTable()
    r = []
    
    @maxnum.keys.each do |band|
      @maxnum[band].times do |n|
        ct = @st                     # current time
        r << sprintf(%Q{<div class='dtc'>})
        if @rsvData[band] == nil or @rsvData[band][n] == nil
          cls = [ "colorGray" ]
          r << printItem( ( @et - ct), "&nbsp;", cls: cls  )
        else
          @rsvData[band][n].each_with_index do |tmp,m|
            hosei = 0
            if tmp[:start ] > ct # ダミーの挿入
              cls = [ "colorGray" ]
              r << printItem( (tmp[:start ] - ct), "&nbsp;", cls: cls  )
              ct = tmp[:start ]
            elsif tmp[:start ] < ct
              hosei = tmp[:start ] - ct
            end
            if tmp[:end] > @et
              hosei -= ( tmp[:end] - @et )
            end
            l = tmp[:end] - tmp[:start] + hosei

            if tmp[:prog] != nil
              cls = [ "item", sprintf("color%d",tmp[:prog][:categoryA][0][0]) ]
            else
              cls = [ "item" ]
            end
              
            if tmp[:stat] != RsvConst::Normal and tmp[:stat] != RsvConst::RecNow
              cls << "alertBD"
            elsif tmp[:jitanExe] == RsvConst::JitanEOn
              cls << "alertGD"
            end

            chname= tmp[:name]
            rid   = tmp[:id]
            stime = Time.at( tmp[:start] ).strftime("%H:%M")
            etime = Time.at( tmp[:end] ).strftime("%H:%M")
            tip   = %Q{#{chname}<br>#{tmp[:title]}<br>#{stime} 〜 #{etime}}
            r << printItem( l, tmp[:title], rid: rid, tip: tip, cls: cls )
                            
            ct = tmp[:end]
          end
          if @et > ct
            cls = [ "colorGray" ]
            r << printItem( ( @et - ct), "&nbsp;", cls: cls  )
          end
        end
        r << sprintf(%Q{</div>})
      end
    end
    r.join("\n")
  end


  
end

