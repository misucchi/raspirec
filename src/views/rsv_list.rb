#!/usr/local/bin/ruby 
# -*- coding: utf-8 -*-

#
#  予約一覧
#


class ReservationList

  def initialize( )
  end

  def getData()
    reserve = DBreserve.new()
    programs = DBprograms.new
    now = Time.now.to_i
    DBaccess.new().open do |db|
      r = reserve.selectSP( db, tend: now)
      # r.each do |r2|
      #   r3 = programs.select( db, chid: r2[:chid], evid: r2[:evid] )
      #   r2[:programs] = r3.first
      # end
      return r
    end
    nil
  end

  def printTD( str, clas: nil, id: nil, rid: nil, style: nil )
    attr = ""
    attr += %Q{class="#{clas.join(" ")}" } if clas != nil
    attr += %Q{id="#{id}" } if id != nil
    attr += %Q{rid="#{rid}" } if rid != nil
    attr += %Q{style="#{style}" } if style != nil
    %Q{ <td #{attr}> #{str} </td>}
  end

  def printTR( data, id: nil, clas: nil )
    attr = []
    attr << %Q(class="#{clas.join(" ")}") if clas != nil
    attr << %Q(id="#{id}") if id != nil
    
    a = [ %Q{ <tr #{attr.join(" ")}> } ]
    a += data
    a << %Q{ </tr> }
    a.join("\n")
  end

  #
  #  データの表示
  #
  def printTable()
    r = []

    data = getData()
    if data != nil
      count = 1
      clas = %w( nowrap ) #item 
      data.each do |t|
        time = Commlib::stet_to_s( t[:start], t[:end] )
        type = t[:type] == 0 ? "手動" : %Q(<a href="/search/fil/#{t[:keyid]}"> 自動 </a>)
        bg = nil
        id = nil
        cate = t[:category]
        bg = %Q(color#{cate})
        clasS = %w( nowrap )

        ( stat, clasS, bg, recf ) = Commlib::statAna( t, clasS, bg  )

        title = %Q(<a class="dialog" rid="#{t[:id]}" recf="#{recf}"> #{t[:title]} </a>)
        st = ( Time.at(t[:start]) - 3600 ).strftime("%Y-%m-%d/%H")
        day = %Q(<a href="rsv_tbl/#{st}"> #{time[0]} </a>)
        time2 = %Q(<a href="rsv_tbl/#{st}"> #{time[1]} #{time[2]} </a>)
        td = []
        td << printTD( count, clas: clas )
        td << printTD( t[:name],clas: clas )
        td << printTD( day,clas: clas )
        td << printTD( time2,clas: clas )
        td << printTD( stat,clas: clasS, id: id )
        td << printTD( type,clas: clas )
        td << printTD( title,clas: clas )
        r << printTR( td, clas: [ bg ] )
        count += 1
      end
    end
    r.join("\n")
  end
end

if File.basename($0) == "reservationList.rb"
  
  
  case ARGV[0]
  when "1"
    puts( pt.printTable( ))
  end
  
end
