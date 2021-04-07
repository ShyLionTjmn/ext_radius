<?php

  $version = "";
  if(preg_match('/devel\.php/', __FILE__)) {
    $version = "_devel";
  };

  $title = "Ext RADIUS";
  $js = "ext_radius$version.js";
  $ajax = "ajax_ext_radius$version.php";
  $local = "local$version.js";

  $local_config = "local$version.php";

  require($local_config);

?>
<!DOCTYPE html>
<HTML>
<HEAD>
<TITLE><?php echo $title; ?></TITLE>
<link rel="icon" href="data:;base64,iVBORw0KGgo=">
<link href="/lib/jq-ui/jquery-ui.min.css" rel="stylesheet">
<link href="/lib/jquery-ui-iconfont/jquery-ui-1.12.icon-font.min.css" rel="stylesheet">
<link href="/lib/datatables.min.css" rel="stylesheet">
<link href="/lib/dataTables.searchHighlight.css" rel="stylesheet">
<SCRIPT type="application/json" id="types"><?php readfile("types.json"); ?></SCRIPT>
<SCRIPT type="text/javascript" src="/lib/jquery.js"></script>
<SCRIPT type="text/javascript" src="/lib/jq-ui/jquery-ui.min.js"></script>
<SCRIPT type="text/javascript" src="/lib/datatables.min.js"></script>
<SCRIPT type="text/javascript" src="/lib/jquery.highlight.js"></script>
<SCRIPT type="text/javascript" src="/lib/dataTables.searchHighlight.min.js"></script>
<SCRIPT type="text/javascript">
var AJAX = "<?php echo $ajax; ?>";
var version = "<?php echo $version; ?>";
</script>
<SCRIPT type="text/javascript" src="/mylib/js/myjslib.js"></script>
<SCRIPT type="text/javascript" src="<?php echo $local; ?>"></script>
<SCRIPT type="text/javascript" src="<?php echo $js; ?>"></script>
<STYLE>
.ns {
    -webkit-touch-callout: none;
    -webkit-user-select: none;
    -khtml-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    user-select: none;
}
.sel {
    -webkit-touch-callout: initial;
    -webkit-user-select: text;
    -khtml-user-select: text;
    -moz-user-select: text;
    -ms-user-select: text;
    user-select: text;
}
.button {
  border: 1px solid #999999;
  color: #222222;
  cursor: pointer;
  padding: .1em;
  margin: .1em;
  background: #e6e6e6;
  display: inline-block;
  height: 1.1em;
  line-height: 100%;
  -webkit-touch-callout: none;
  -webkit-user-select: none;
  -khtml-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}
.button:hover, .button:focus {
  background: #dadada;
}
.button:active {
  background: #e6e6e6;
}
.bigbutton {
  border: 1px solid #999999;
  color: #222222;
  cursor: pointer;
  padding: .5em;
  margin: .5em;
  background: #e6e6e6;
  display: inline-block;
  -webkit-touch-callout: none;
  -webkit-user-select: none;
  -khtml-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}
.bigbutton:hover, .button:focus {
  background: #dadada;
}
.bigbutton:active {
  background: #e6e6e6;
}
table.dataTable tfoot td {
  padding-left: 10px;
  padding-right: 10px;
}
.indicator {
  border: 1px solid #999999;
  color: #555555;
  padding: .1em;
  margin: .1em;
  display: inline-block;
  position: fixed;
  right: 1em;
  top: 1em;
}
</STYLE>
</HEAD>
<BODY>
</BODY>
</HTML>
