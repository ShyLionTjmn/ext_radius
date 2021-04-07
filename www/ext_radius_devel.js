let DEBUG = false;

const R_SUPER = 'super';

let s_wsp={"white-space": "pre"};
let s_vat={"vertical-align": "top"};

let ss={};
let us={};

const right_cols=[
  { "right": R_SUPER,       "descr": "Права суперпользователя",           "short_name": "Супр",
    "on_css": {"background-color": "lightgreen", "color": "black"},
    "off_css": {"background-color": "lightgrey", "color": "grey"},
    "row": 1
  }
];

function user_has_right(right, rights_string) {
  let reg=new RegExp("(?:^|,) *"+RegExp.escape(right)+" *(?:,|$)","i");
  if(reg.test(rights_string)) {
    return true;
  };
  return false;
};

function wdhm(time) {
  let w=Math.floor(time / (7*24*60*60));
  time = time - w*(7*24*60*60);

  let d=Math.floor(time / (24*60*60));
  time = time - d*(24*60*60);

  let h=Math.floor(time / (60*60));
  time = time - h*(60*60);

  let m=Math.floor(time / 60);
  let s=time - m*60;

  let ret="";
  if(w > 0) {
    ret = String(w)+" н. ";
  };
  if(d > 0 || w > 0) {
    ret += String(d)+" д. ";
  };
  if(h > 0 || d > 0 || w > 0) {
    ret += String(h)+" ч. ";
  };
  if(m > 0 || h > 0 || d > 0 || w > 0) {
    ret += String(m)+" м. ";
  };

  ret += String(s)+" с.";

  return ret;
};

function save_local(key, value) {
  localStorage.setItem(key+"_"+user_self_id, JSON.stringify(value));
};

function get_local(key, on_error=undefined) {
  let js=localStorage.getItem(key+"_"+user_self_id);
  if(js == undefined || js == "null") return on_error;
  try {
    return JSON.parse(localStorage.getItem(key+"_"+user_self_id));
  } catch(e) {
    return on_error;
  };
};

function info(text) {
  return $(LABEL)
   .addClass("ui-icon").addClass("ui-icon-info")
   .css({"font-size": "xx-small", "color": "gray", "margin-right": "0.2em"})
   .title(text)
   .data("text", text)
   .on("click", function() {
     show_dialog($(this).data("text"));
   })
  ;
};

function user_logged_in(userdata) {
  $("#mainmenu").empty();
  $("#usermenu").empty();
  $("#head").empty();
  $("#contents").empty();

  user_rights=userdata["user_rights"];
  user_self_id=userdata["user_self_id"];

  $("#mainmenu").append (
    $(LABEL).addClass("bigbutton").html("&#x1F464")
     .click(function() {
       $("#usermenu").show();
       $("#mainmenu").hide();
    })
  );


  $("#mainmenu").append( $(LABEL).text("Сеансы").addClass("page_sessions").addClass("default_action_button").addClass("bigbutton").click(list_sessions) );
  $("#mainmenu").append( $(LABEL).text("Учетные записи").addClass("page_accounts").addClass("bigbutton").click(list_accounts) );
  $("#mainmenu").append( $(LABEL).text("Журнал").addClass("page_journal").addClass("bigbutton").click(journal) );


  $("#usermenu")
   .append( $(LABEL).text("Текущий пользователь: ") )
   .append( $(LABEL).text(userdata["user_name"]+" ("+userdata["user_login"]+")").title(userdata["user_rights"]) )
   .append( $(LABEL).text("Выйти").addClass("button").click(function() {
       run_query({"action": "logout"}, function() {
         $("#mainmenu").empty();
         $("#usermenu").empty();
         $("#head").empty();
         $("#contents").empty();

         user_self_id=undefined;
         user_rights="";

         run_query({'action': 'user_check'}, function(data) {
           user_logged_in(data['ok']);
         });
       });
     })
   )
   .append( $(BR) )
   .append( $(LABEL).text("Сброс настроек").addClass("button").click(function() {
       localStorage.clear();
     })
   )
  ;

  let last_page=get_local("last_page");
  if(typeof(last_page) === 'string' && $("."+last_page).length == 1) {
    $("."+last_page).trigger("click");
  } else {
    $(".default_action_button").trigger("click");
  };
};


$( document ).ready(function() {

  window.onerror=function(errorMsg, url, lineNumber) {
    alert("Error occured: " + errorMsg + ", at line: " + lineNumber);//or any message
    return false;
  };

  $("BODY").append (
    $(DIV).css({"position": "fixed", "right": "0.5em", "top": "0.5em", "min-width": "2em",
                "border": "1px solid black", "background-color": "lightgrey"
    }).prop("id", "indicator").text("Запуск интерфейса...")
  );
  if(version.match(/devel/)) {
    $("BODY")
     .append ( $(DIV).css({"position": "fixed", "right": "1em", "top": "1em", "color": "red" }).text("DEVELOPMENT"))
     .append ( $(DIV).css({"position": "fixed", "left": "1em", "top": "1em", "color": "red" }).text("DEVELOPMENT"))
     .append ( $(DIV).css({"position": "fixed", "right": "1em", "bottom": "1em", "color": "red" }).text("DEVELOPMENT"))
     .append ( $(DIV).css({"position": "fixed", "left": "1em", "bottom": "1em", "color": "red" }).text("DEVELOPMENT"))
    ;
  };

  $(document).ajaxComplete(function() {
    $("#indicator").text("Запрос завершен").css("background-color", "lightgreen");
  });

  $(document).ajaxStart(function() {
    $("#indicator").text("Запрос ...").css("background-color", "yellow");
  });

  $("BODY").append (
    $(LABEL).addClass("button").text("Меню")
     .css({"display": "inline-block", "position": "absolute", "z-index": 1000001, "left": "0.1em", "top": "0.1em"})
     .click(function() {
       $("#mainmenu").toggle();
       $("#usermenu").hide();
     })
  );
  $("BODY").append (
    $(DIV).prop("id", "mainmenu").css({"display": "inline-block", "position": "absolute", "z-index": 1000000,
           "left": "5em", "top": "0.5em", "text-align": "center"
     })
  );

  $("BODY").append (
    $(DIV).prop("id", "usermenu").css({"display": "inline-block", "position": "absolute", "z-index": 1000000,
           "left": "5em", "top": "0.5em",
           "background-color": "white", "padding": "0.5em", "border": "1px solid gray"
     }).hide()
  );

  $("BODY").append (
    $(DIV).prop("id", "head").css("text-align", "center")
  );

  $("BODY").append (
    $(DIV).prop("id", "contents").css({"margin-top": "2em"})
  );
  contents_div=$("#contents");
  if(contents_div.length != 1) return;

  run_query({"action": "user_check"}, function(data) {
    user_logged_in(data['ok']);
  });
});

function ses_row(s_id) {
  if(typeof(ss[s_id]) === 'undefined') {
    error_at();
    return;
  };

  let tr=$(TR).data("id", s_id);

  let agent=ss[s_id]['s_agent'];
  if(ss[s_id]['s_agent'] == 1) {
    agent="PPPoE";
  } else if(ss[s_id]['s_agent'] == 12) {
    agent="IPoE";
  };

  let status_label=$(LABEL).css({'font-size': 'x-small'});

  if(ss[s_id]['s_kill'] == 0) {
    if(ss[s_id]['s_state'] == 0) {
      status_label.text("Ok.").css({'color': 'green'}).title('Сеанс в работе');
    } else if(ss[s_id]['s_state'] == 1) {
      status_label.text("Ред.").css({'color': 'darkorange'}).title('Сеанс с редиректом на билинг');
    } else {
      status_label.text("Нзв.").css({'color': 'darkgray'}).title('Неизвестный сеанс');
    };
  } else {
    status_label.text("Сбрс.").css({'color': 'red'}).title('Запланирован сброс');
  };

  tr.append( $(TD).text(s_id) ); // 0
  tr
   .append( $(TD)
     .append( $(LABEL).text(ss[s_id]['s_login']) )
     .append( $(BR) )
     .append( $(LABEL).text(agent).css({'float': 'right', 'font-size': 'smaller'}) )
     .append( $(BR) )
     .append( status_label )
   )
  ; // 1
  tr
   .append( $(TD)
     .append( $(LABEL).text(ss[s_id]['s_ip']) )
     .append( $(BR) )
     .append( $(LABEL).text(ss[s_id]['s_mac']) )
   )
  ; // 2
  tr.append( $(TD).append( $(LABEL).text(ss[s_id]['s_speed']) ) ); // 3
  tr .append( $(TD) .append( $(LABEL).text(ss[s_id]['s_start']) )) ; // 4
  tr
   .append( $(TD)
     .append( $(LABEL).text(from_unix_time(ss[s_id]['s_start'])))
     .append( $(BR) )
     .append( $(LABEL).text( wdhm(unix_timestamp() - ss[s_id]['s_start']) ) )
   )
  ; // 5
  tr.append( $(TD).append( $(LABEL).text(Number(ss[s_id]['s_bytes_in']) + Number(ss[s_id]['s_bytes_out'])) ) ); // 6

  tr
   .append( $(TD)
     .append( $(LABEL).text(GMK(ss[s_id]['s_bytes_in'])) )
     .append( $(BR) )
     .append( $(LABEL).text(GMK(ss[s_id]['s_bytes_out'])) )
   )
  ; // 7

  tr
   .append( $(TD)
     .append( $(LABEL).text(ss[s_id]['s_anumber']) )
   )
  ; // 8

  tr
   .append( $(TD)
     .append( $(LABEL).text(ss[s_id]['s_name']) )
     .append( $(BR) )
     .append( $(LABEL).text(ss[s_id]['u_address']) )
   )
  ; // 9

  let act_td=$(TD);

  tr.append( act_td );

  act_td
   .css({"min-width": "10em"})
   .css(s_vat)
   .css(s_wsp)
  ;

  if(ss[s_id]['s_kill'] == 0) {
    act_td
     .append( $(LABEL).addClass("reset").addClass("button").text("Сброс")
       .click(function() {
         let tr=$(this).closest("TR");
         tr.find(".real_reset").show();
         tr.find(".cancel").show();
         $(this).hide();
       })
     )
     .append( $(LABEL).addClass("cancel").addClass("button").text("Отмена").hide()
       .click(function() {
         let tr=$(this).closest("TR");
         tr.find(".real_reset").hide();
         tr.find(".reset").show();
         $(this).hide();
       })
     )
     .append( $(BR) )
     .append( $(LABEL).addClass("real_reset").addClass("button").text("Реально Сброс").hide()
       .click(function() {
         let tr=$(this).closest("TR");
         run_query({"action": "kill_session", "s_id": tr.data("id")}, function(data) {
           tr.css({"text-decoration": "line-through"});
           tr.find(".real_reset").hide();
           tr.find(".reset").hide();
           tr.find(".cancel").hide();
         });
       })
     )
    ;
  } else {
    tr.css({"text-decoration": "line-through"});
  };

  tr.find("TD").css(s_wsp);

  return tr;
};

function list_sessions() {
  save_local("last_page", "page_sessions");
  $("#mainmenu").hide();
  $("#usermenu").hide();

  contents_div.empty();

  contents_div.append( $(DIV).text("Сеансы").css({"font-size": "x-large", "text-align": "center"}) );
  ss={};

  contents_div
   .append( $(DIV).css({"text-align": "center"})
     .append( $(LABEL).prop("id", "refresh").addClass("bigbutton").text("Обновить")
       .click(function() {
         run_query({"action": "list_sessions"}, function(data) {

           let table_dt=$("#sessions_table").DataTable();
           table_dt.rows().remove();

           if(typeof(data['ok']['ss']) !== 'undefined') {
             ss=data['ok']['ss'];
           };

           let total_sessions=0;
           let total_in_table=0;

           for(s_id in ss) {
             total_sessions++;
             if( true
             ) {
               let new_row=ses_row(s_id);
               table_dt.row.add(new_row);
               total_in_table++;
             };
           };
           table_dt.draw();

           $("#summary").empty()
            .append( $(LABEL).text("Всего: ") )
            .append( $(LABEL).text(total_in_table) )
           ;
         });
       })
     )
   )
  ;

  contents_div.append( $(DIV).prop("id", "summary") );

  let table=$(TABLE).prop("id", "sessions_table");
  $(THEAD)
   .append( $(TR)
     .append( $(TH).text("id") ) // 0
     .append( $(TH).text("Логин") ) // 1
     .append( $(TH).html("IP<BR>MAC") ) // 2
     .append( $(TH).text("Скорость") ) // 3
     .append( $(TH).text("") ) // start sorting value // 4
     .append( $(TH).text("Начало") ) // 5
     .append( $(TH).text("") ) // traffic sorting value // 6
     .append( $(TH).text("Траффик (от/к)") ) // 7
     .append( $(TH).text("Договор") ) // 8
     .append( $(TH).html("Имя<BR>Адрес") ) // 9
     .append( $(TH).text("") ) // buttons  // -1
   )
   .appendTo(table)
  ;
  $(TBODY).appendTo(table);

  table.appendTo(contents_div);
  let table_dt=table.DataTable({
    "columnDefs": [
      { "visible": false, "searchable": false, "orderable": false, "targets": [4,6] },
      { "orderData": [4], "orderable": true, "searchable": true, "targets": [5] },
      { "orderData": [6], "orderable": true, "searchable": true, "targets": [7] },
      { "orderable": false, "searchable": false, "targets": [-1] },
    ],
    "order": [[ 0, "asc"]],
    "scrollY": "600px",
    "scrollCollapse": true,
    "paging": true,
    "searchHighlight": true
  });

  $("input[type=search]").focus();



  $("#refresh").trigger("click");
};

let bill_states={};

bill_states[1] = "По балансу";
bill_states[2] = "Вручную пользователем";
bill_states[3] = "Администратором";
bill_states[4] = "По балансу";
bill_states[5] = "Лимит траффика";
bill_states[10] = "Отключена";

function acc_row(u_vg_id) {
  if(typeof(us[u_vg_id]) === 'undefined') {
    error_at();
    return;
  };

  let tr=$(TR).data("id", u_vg_id);

  let agent=us[u_vg_id]['u_agent'];
  if(us[u_vg_id]['u_agent'] == 1) {
    agent="PPPoE";
  } else if(us[u_vg_id]['u_agent'] == 12) {
    agent="IPoE";
  };

  let status_label=$(LABEL).css({'font-size': 'x-small'});

  if(us[u_vg_id]['u_bill_state'] == 0) {
    status_label.text("Ok.").css({'color': 'green'}).title('Учетная запись включена');
  } else {
    if(typeof(bill_states[ us[u_vg_id]['u_bill_state'] ]) !== 'undefined') {
      status_label.text("Откл.").css({'color': 'darkorange'}).title('Учетная запись заблокирована. Причина: '+bill_states[ us[u_vg_id]['u_bill_state'] ]);
    } else {
      status_label.text("Откл.").css({'color': 'darkorange'}).title('Учетная запись заблокирована, код '+us[u_vg_id]['u_bill_state']);
    };
  };

  tr.append( $(TD).text(u_vg_id) ); // 0
  tr
   .append( $(TD)
     .append( $(LABEL).text(us[u_vg_id]['u_login']) )
     .append( $(BR) )
     .append( $(LABEL).text(agent).css({'float': 'right', 'font-size': 'smaller'}) )
     .append( $(BR) )
     .append( status_label )
   )
  ; // 1
  tr
   .append( $(TD)
     .append( $(LABEL).text(us[u_vg_id]['u_ips']) )
   )
  ; // 2
  tr.append( $(TD).append( $(LABEL).text(us[u_vg_id]['u_speed']) ) ); // 3
  tr.append( $(TD).append( $(LABEL).text(from_unix_time(us[u_vg_id]['u_last_start'])) ) ); // 4
  tr.append( $(TD).append( $(LABEL).text(us[u_vg_id]['u_anumber']) ) ); // 5
  tr
   .append( $(TD)
     .append( $(LABEL).text(us[u_vg_id]['u_name']) )
     .append( $(BR) )
     .append( $(LABEL).text(us[u_vg_id]['u_address']) )
   )
  ; // 6

  let act_td=$(TD);

  tr.append( act_td );

  act_td
   .css({"min-width": "10em"})
   .css(s_vat)
   .css(s_wsp)
  ;

  tr.find("TD").css(s_wsp);

  return tr;
};

function list_accounts() {
  save_local("last_page", "page_accounts");
  $("#mainmenu").hide();
  $("#usermenu").hide();

  contents_div.empty();

  contents_div.append( $(DIV).text("Учетные записи").css({"font-size": "x-large", "text-align": "center"}) );
  us={};

  contents_div
   .append( $(DIV).css({"text-align": "center"})
     .append( $(LABEL).prop("id", "refresh").addClass("bigbutton").text("Обновить")
       .click(function() {
         run_query({"action": "list_accounts"}, function(data) {

           let table_dt=$("#accounts_table").DataTable();
           table_dt.rows().remove();

           if(typeof(data['ok']['us']) !== 'undefined') {
             us=data['ok']['us'];
           };

           let total_accounts=0;
           let total_in_table=0;

           for(u_vg_id in us) {
             total_accounts++;
             if( true
             ) {
               let new_row=acc_row(u_vg_id);
               table_dt.row.add(new_row);
               total_in_table++;
             };
           };
           table_dt.draw();

           $("#summary").empty()
            .append( $(LABEL).text("Всего: ") )
            .append( $(LABEL).text(total_in_table) )
           ;
         });
       })
     )
   )
  ;

  contents_div.append( $(DIV).prop("id", "summary") );

  let table=$(TABLE).prop("id", "accounts_table");
  $(THEAD)
   .append( $(TR)
     .append( $(TH).text("id") ) // 0
     .append( $(TH).text("Логин") ) // 1
     .append( $(TH).text("IP") ) // 2
     .append( $(TH).text("Скорость") ) // 3
     .append( $(TH).text("Активность") ) // 4
     .append( $(TH).text("Договор") ) // 5
     .append( $(TH).html("Имя<BR>Адрес") ) // 6
     .append( $(TH).text("") ) // buttons  // 7
   )
   .appendTo(table)
  ;
  $(TBODY).appendTo(table);

  table.appendTo(contents_div);
  let table_dt=table.DataTable({
    "columnDefs": [
      { "orderable": false, "searchable": false, "targets": [-1] },
    ],
    "order": [[ 0, "asc"]],
    "scrollY": "600px",
    "scrollCollapse": true,
    "paging": true,
    "searchHighlight": true
  });

  $("input[type=search]").focus();

  $("#refresh").trigger("click");
};

function jnl_row(i) {
  if(typeof(es[i]) === 'undefined') {
    error_at();
    return;
  };

  let tr=$(TR).data("id", es[i]['h_id']).data("table", es[i]['h_table']);

  let agent=es[i]['h_agent'];
  if(es[i]['h_agent'] == 1) {
    agent="PPPoE";
  } else if(es[i]['h_agent'] == 12) {
    agent="IPoE";
  };

  let status_label=$(LABEL).css({'font-size': 'x-small'});

  if(es[i]['h_kill'] == 0) {
    if(es[i]['h_state'] == 0) {
      status_label.text("Ok.").css({'color': 'green'}).title('Сеанс в работе');
    } else if(es[i]['h_state'] == 1) {
      status_label.text("Ред.").css({'color': 'darkorange'}).title('Сеанс с редиректом на билинг');
    } else {
      status_label.text("Нзв.").css({'color': 'darkgray'}).title('Неизвестный сеанс');
    };
  } else {
    status_label.text("Сбрс.").css({'color': 'red'}).title('Запланирован сброс');
  };

  tr.append( $(TD).text(es[i]['h_id']) ); // 0
  tr
   .append( $(TD)
     .append( $(LABEL).text(es[i]['h_login']) )
     .append( $(BR) )
     .append( $(LABEL).text(agent).css({'float': 'right', 'font-size': 'smaller'}) )
     .append( $(BR) )
     .append( status_label )
   )
  ; // 1
  tr
   .append( $(TD)
     .append( $(LABEL).text(es[i]['h_ip']) )
     .append( $(BR) )
     .append( $(LABEL).text(es[i]['h_mac']) )
   )
  ; // 2
  tr.append( $(TD).append( $(LABEL).text(es[i]['h_speed']) ) ); // 3

  tr.append( $(TD) .append( $(LABEL).text(es[i]['h_auth']) )) ; // 4
  tr.append( $(TD).append( $(LABEL).text(from_unix_time(es[i]['h_auth'])))) ; // 5

  tr .append( $(TD) .append( $(LABEL).text(es[i]['h_stop']) )) ; // 6

  let dur="";

  if(es[i]['h_stop'] > 0 && es[i]['h_start'] > 0) {
    dur=wdhm(es[i]['h_stop'] - es[i]['h_start']);
  };

  tr
   .append( $(TD)
     .append( $(LABEL).text(from_unix_time(es[i]['h_stop'], false, "")) )
     .append( $(BR) )
     .append( $(LABEL).text( dur ) )
   )
  ; // 7

  tr.append( $(TD).append( $(LABEL).text(Number(es[i]['h_bytes_in']) + Number(es[i]['h_bytes_out'])) ) ); // 8

  tr
   .append( $(TD)
     .append( $(LABEL).text(GMK(es[i]['h_bytes_in'])) )
     .append( $(BR) )
     .append( $(LABEL).text(GMK(es[i]['h_bytes_out'])) )
   )
  ; // 9

  tr
   .append( $(TD)
     .append( $(LABEL).text(es[i]['h_anumber']) )
   )
  ; // 10

  tr
   .append( $(TD)
     .append( $(LABEL).text(es[i]['h_name']) )
     .append( $(BR) )
     .append( $(LABEL).text(es[i]['u_address']) )
   )
  ; // 11

  let stop_reason=es[i]['h_term_cause'];
  let stop_td=$(TD).append( $(SPAN).text(stop_reason) );
  stop_td.append( $(BR) );
  if(es[i]['h_error'] > 1) {
    stop_td.append( $(SPAN).text(String(es[i]['h_error'])+" событий за период") );
  };

  tr.append( stop_td ); // -1

  tr.find("TD").css(s_wsp).css(s_vat);

  return tr;
};

function journal() {
  save_local("last_page", "page_journal");
  $("#mainmenu").hide();
  $("#usermenu").hide();

  contents_div.empty();

  contents_div.append( $(DIV).text("Журнал").css({"font-size": "x-large", "text-align": "center"}) );
  es={};

  contents_div
   .append( $(DIV).css({"text-align": "center"})
     .append( $(INPUT).prop("type", "search").prop("id", "search_query")
       .css({"min-width": "20em", "font-size": "larger"})
     )
     .append( $(LABEL).prop("id", "refresh").addClass("bigbutton").text("Поиск")
       .click(function() {
         let query=$("#search_query").val();
         let limit=$("#search_limit").val();

         if(!String(limit).match(/^\d{1,4}$/)) {
           $("#search_limit").animateHighlight();
           return;
         };

         let from_date=$("#search_from").datepicker("getDate");
         if(from_date === null) {
           $("#search_from").animateHighlight();
           return;
         };
         let to_date=$("#search_to").datepicker("getDate");
         if(to_date === null) {
           $("#search_to").animateHighlight();
           return;
         };

         let from_add=0;
         let to_add=24*60*60-1

         let from_time=String($("#search_from_time").val()).trim();
         if(from_time != "") {
           let m=from_time.match(/^([0-9]{2}):?([0-9]{2})$/);
           if(m === null) {
             $("#search_from_time").animateHighlight();
             return;
           };
           if(m[1] > 23 || m[2] > 59) {
             $("#search_from_time").animateHighlight();
             return;
           };

           from_add=60*60*Number(m[1]) + 60*Number(m[2]);
         };

         
         let to_time=String($("#search_to_time").val()).trim();
         if(to_time != "") {
           let m=to_time.match(/^([0-9]{2}):?([0-9]{2})$/);
           if(m === null) {
             $("#search_to_time").animateHighlight();
             return;
           };
           if(m[1] > 23 || m[2] > 59) {
             $("#search_to_time").animateHighlight();
             return;
           };

           to_add=60*60*Number(m[1]) + 60*Number(m[2]) + 59;
         };


         
         let from_unix=unix_timestamp(from_date)+from_add;
         let to_unix=unix_timestamp(to_date)+to_add;

         if(from_unix >= to_unix) {
           $("#search_to,#search_from,#search_from_time,#search_to_time").animateHighlight();
           return;
         };

         //alert(from_unix_time(from_unix) + " : " +from_unix_time(to_unix));

         run_query({"action": "search_journal", "query": query, "limit": limit, "from": from_unix, "to": to_unix}, function(data) {
           
           if(version.match(/devel/)) {
             console.log(data['ok']['query']);
           };

           let table_dt=$("#journal_table").DataTable();
           table_dt.rows().remove();

           es=data['ok']['es'];

           let total_in_table=0;

           for(i in es) {
             if( true
             ) {
               let new_row=jnl_row(i);
               table_dt.row.add(new_row);
               total_in_table++;
             };
           };
           table_dt.draw();

           $("#summary").empty()
            .append( $(LABEL).text("Всего найдено: ") )
            .append( $(LABEL).text(data['ok']['found']) )
            .append( $(LABEL).text("; в таблице: ") )
            .append( $(LABEL).text(total_in_table) )
           ;
           if(total_in_table < Number(data['ok']['found'])) {
             $("#summary").append( $(LABEL).text( " (достигнут лимит)").css("color", "red") );
           };
           //alert(data['ok']['query']);

           $("#search_query").focus();
         });
       })
     )
   )
   .append( $(DIV).css({"text-align": "center", "line-height": "200%"})
     .append( $(LABEL).text("Лимит: ") )
     .append( $(INPUT).prop("type", "number").prop("id", "search_limit")
       .val(100)
       .enterKey(function() { $("#refresh").trigger("click"); })
     )
     .append( $(LABEL).text(" С: ") )
     .append( $(INPUT).prop("id", "search_from")
       .enterKey(function() { $("#refresh").trigger("click"); })
     )
     .append( $(INPUT).prop("id", "search_from_time").css({"margin-left": "1em", "width": "3em"}).prop({"placeholder": "00:00"})
       .enterKey(function() { $("#refresh").trigger("click"); })
     )
     .append( $(LABEL).text(" До: ") )
     .append( $(INPUT).prop("id", "search_to")
       .enterKey(function() { $("#refresh").trigger("click"); })
     )
     .append( $(INPUT).prop("id", "search_to_time").css({"margin-left": "1em", "width": "3em"}).prop({"placeholder": "23:59"})
       .enterKey(function() { $("#refresh").trigger("click"); })
     )
     .append( $(BR) )
     .append( $(LABEL).text("Последние: ") )
     .append( $(LABEL).addClass("last_x").addClass("button").text("5 мин.").data("dur", 5*60).css({"margin-right": "1em"}) )
     .append( $(LABEL).addClass("last_x").addClass("button").text("30 мин.").data("dur", 30*60).css({"margin-right": "1em"}) )
     .append( $(LABEL).addClass("last_x").addClass("button").text("Час").data("dur", 60*60).css({"margin-right": "1em"}) )
     .append( $(LABEL).addClass("last_x").addClass("button").text("День").data("dur", 24*60*60).css({"margin-right": "1em"}) )
     .append( $(LABEL).addClass("button").text("Сброс").css({"margin-left": "1em"})
       .click(function() {
         $("#search_from").datepicker({'dateFormat': "yy.mm.dd", 'firstDay': 1}).datepicker("setDate", "-1m");
         $("#search_to").datepicker({'dateFormat': "yy.mm.dd", 'firstDay': 1}).datepicker("setDate", "+0");
         $("#search_from_time").val("");
         $("#search_to_time").val("");
       })
     )
   )
  ;

  $("#search_from").datepicker({'dateFormat': "yy.mm.dd", 'firstDay': 1}).datepicker("setDate", "-1m");
  $("#search_to").datepicker({'dateFormat': "yy.mm.dd", 'firstDay': 1}).datepicker("setDate", "+0");


  contents_div.append( $(DIV).prop("id", "summary").append( $(LABEL).text("Результат запроса:") ) );

  let table=$(TABLE).prop("id", "journal_table");
  $(THEAD)
   .append( $(TR)
     .append( $(TH).text("id") ) // 0
     .append( $(TH).text("Логин") ) // 1
     .append( $(TH).html("IP<BR>MAC") ) // 2
     .append( $(TH).text("Скорость") ) // 3
     .append( $(TH).text("") ) // auth sorting value // 4
     .append( $(TH).html("Начало") ) // 5
     .append( $(TH).text("") ) // stop sorting value // 6
     .append( $(TH).html("Окончание<BR>Длительность") ) // 7
     .append( $(TH).text("") ) // traffic sorting value // 8
     .append( $(TH).text("Траффик (от/к)") ) // 9
     .append( $(TH).text("Договор") ) // 10
     .append( $(TH).html("Имя<BR>Адрес") ) // 11
     .append( $(TH).text("Причина разрыва/отказа") ) // buttons  // -1
   )
   .appendTo(table)
  ;
  $(TBODY).appendTo(table);

  table.appendTo(contents_div);
  let table_dt=table.DataTable({
    "columnDefs": [
      { "visible": false, "searchable": false, "orderable": false, "targets": [4,6,8] },
      { "orderData": [4], "orderable": true, "searchable": true, "targets": [5] },
      { "orderData": [6], "orderable": true, "searchable": true, "targets": [7] },
      { "orderData": [8], "orderable": true, "searchable": true, "targets": [9] },
    ],
    "order": [[ 4, "desc"]],
    "scrollY": "600px",
    "scrollCollapse": true,
    "paging": true,
    "searchHighlight": true
  });

  $("#search_query").focus();
  $("#search_query")
   .enterKey(function() {
     $("#refresh").trigger("click");
   })
  ;

  $(".last_x").click(function() {
    let dur=$(this).data("dur");
    if(typeof(dur) === 'number') {
      let start = unix_timestamp();
      start -= dur;
      let start_date=new Date(start*1000);

      let start_time=addZero(start_date.getHours()) + ":"+addZero(start_date.getMinutes());

      start_date.setHours(0);
      start_date.setMinutes(0);
      start_date.setSeconds(0);

      $("#search_from_time").val(start_time);
      $("#search_from").datepicker("setDate", start_date);

      $("#search_from_time,#search_from").animateHighlight("&#AAFFAA");
    };
  });

  //$("#refresh").trigger("click");
};
