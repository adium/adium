<?
	// from the command line:
	// php -q fire2adium.php
	
	// set this one variable
	$system_username = "";
	
	// you could set these too
	$chat_username = "Fire Import";
	$chat_service = "AIM";
	
	// shouldn't need to set anything below
	$fire_base = "/Users/${system_username}/Library/Application Support/Fire/Sessions";
	$adium_base = "/Users/${system_username}/Library/Application Support/Adium 2.0/Users/Default/Logs/${chat_service}.${chat_username}";
	
	if(!is_dir($adium_base))
		mkdir($adium_base, 0755);
	
	$fire_log_dirs = array();
	$handle = opendir($fire_base);
	while($file = readdir($handle))
	{
		if($file != "." && $file != ".." && is_dir("${fire_base}/${file}"))
			$fire_log_dirs[] = $file;
	}

	foreach($fire_log_dirs as $fire_log_dir)
	{
		list($chat_username_receiver,$chat_service_receiver) = explode('-', $fire_log_dir);
		$adium_log_dir = "$chat_username_receiver";
		mkdir("${adium_base}/${adium_log_dir}", 0755);
		
		$fire_logs = array();
		$handle = opendir("${fire_base}/${fire_log_dir}");
		while($file = readdir($handle))
		{
			if($file != "." && $file != ".." && !is_dir("${fire_log_path}/${fire_log_dir}/${file}"))
				$fire_logs[] = $file;
		}
		
		foreach($fire_logs as $fire_log)
		{
			list($date, $crap) = explode(',', $fire_log);
			list($year,$month,$day) = explode('-', $date);
			copy("${fire_base}/${fire_log_dir}/${fire_log}", "${adium_base}/${adium_log_dir}/${chat_username_receiver} (${year}|${month}|${day}).html");
		}
	}
	
	echo "done\n";
?>

