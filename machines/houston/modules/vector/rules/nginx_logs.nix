{
  sources = {
    file_nginx_logs = {
      type = "file";
      include = [
        "/var/log/nginx/private.log"
      ];
    };
  };

  transforms = {
    nginx_logs_cleaned = {
      type = "remap";
      inputs = [ "file_nginx_logs" ];
      source = ''
        # Convert ISO timestamp to unix timestamp if available, otherwise use current time
        .unix_timestamp = to_unix_timestamp(parse_timestamp!(.timestamp, "%Y-%m-%dT%H:%M:%S%.fZ"))
        .service = "nginx_logs"
        .transport = "logs_file"

        .meta = {}
        .meta.risk_level = "unknown"
        .meta.risk_type = "unknown"
        .meta.data_type = "unknown"
        .meta.data_value = "unknown"
        .meta.ip = "unknown"
        .meta.http_url = "unknown"
        .meta.http_code = "unknown"
        .meta.http_method = "unknown"
        .meta.http_user_agent = "unknown"
        .meta.http_host = "unknown"

        del(.file)
        del(.source_type)



        # Parse nginx access log format
        # Example: radio.ma-cabane.eu:443 1.2.3.4 - - [30/Sep/2025:06:10:44 +0000] "GET /?channel=1%20FM%20Reggae HTTP/2.0" 200 133 "-" "Mozilla/5.0..."
        nginx_match = parse_regex(.message, r'(?P<host>[^:]+):(?P<port>\d+)\s+(?P<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+-\s+-\s+\[(?P<timestamp>[^\]]+)\]\s+"(?P<method>[A-Z]+)\s+(?P<url>[^"]*)\s+HTTP/[^"]*"\s+(?P<status>\d+)\s+(?P<size>\d+)\s+"(?P<referer>[^"]*)"\s+"(?P<user_agent>[^"]*)"') ?? null

        if (nginx_match != null) {
          .meta.ip = nginx_match.ip
          .meta.http_host = nginx_match.host
          .meta.http_url = nginx_match.url
          .meta.http_code = nginx_match.status
          .meta.http_method = nginx_match.method
          .meta.http_user_agent = nginx_match.user_agent
          .meta.data_type = "unknow"
          .meta.data_value = "unknown"
        } else {
          .meta.data_value = .message
        }

        ########################################################################
        # Risk classification based on HTTP patterns
        ########################################################################

        if (nginx_match != null) {
          # Check for suspicious URLs/patterns
          if match!(nginx_match.url, r'(?i)(\.\./|\.\.\\|/\.git/|/etc/|/var/|/proc/|/sys/)') ||
             match!(nginx_match.url, r'(?i)(toto|admin|phpmyadmin|wp-admin|login|xmlrpc|cgi-bin)') ||
             match!(nginx_match.url, r'(?i)\.(php|asp|aspx|jsp|cgi)$') ||
             match!(nginx_match.url, r'(?i)(shell|cmd|exec|eval|script)') {
            .meta.data_type = "exploit"
            .meta.data_value = "privilege escalation"

            .meta.risk_level = "critical"
            .meta.risk_type = "HTTP exploit"
          }

          # Check for AI bot
          if .meta.risk_level == "unknown" {
            bot_match = parse_regex(nginx_match.user_agent, r'(?i)(gptbot|oai-searchbot|chatgpt-user|anthropic-ai|claudebot|claude-web|perplexitybot|perplexity-user|google-extended|amazonbot|applebot-extended|bytespider|duckassistbot|cohere-ai|ai2bot|ccbot|diffbot|youbot|mistralai-user)') ?? null
            if (bot_match != null) {
              .meta.data_type = "bot"
              .meta.data_value = bot_match[0]

              .meta.risk_level = "critical"
              .meta.risk_type = "AI bot"
            }
          }

          # Check for known specific bots first
          if .meta.risk_level == "unknown" {
            bot_match = parse_regex(nginx_match.user_agent, r'(?i)(googlebot|bingbot|slurp|duckduckbot|baiduspider|yandexbot|facebookexternalhit|twitterbot|linkedinbot|whatsapp|telegrambot|discordbot|slackbot|msnbot|applebot|semrushbot|ahrefsbot|mj12bot|dotbot|screaming frog|sitebulb)') ?? null
            if (bot_match != null) {
              .meta.data_type = "crawler"
              .meta.data_value = bot_match[0]

              .meta.risk_level = "none"
              .meta.risk_type = "Search engine bot"
            }
          }
          
          # Check for unknown specific bots first
          if .meta.risk_level == "unknown" {
            if match!(nginx_match.user_agent, r'(?i)(bot|crawl|spider|scan|curl|wget|python|perl|java)') {
              .meta.data_type = "crawler"
              .meta.data_value = "generic"
              
              .meta.risk_level = "none"
              .meta.risk_type = "unknown bot request"
            }
          }
        }

        # Create reduced message by removing variable data
        if .message != null && .message != "" && nginx_match != null {
          reducedmessage, _ = nginx_match.method + " " + nginx_match.url
          # Remove sensitive parameters but keep structure
          reducedmessage = replace(reducedmessage, r'[?&]token=[^&]*', "?token=[SENSITIVE]")
          reducedmessage = replace(reducedmessage, r'[?&]password=[^&]*', "?password=[SENSITIVE]")
          reducedmessage = replace(reducedmessage, r'[?&]key=[^&]*', "?key=[SENSITIVE]")

          .meta.reducedmessage = to_string(.meta.risk_type) + " // " + reducedmessage
        } else {
          .meta.reducedmessage = ""
        }

        del(.message)
      '';
    };
  };
}
