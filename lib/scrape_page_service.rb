require "mechanize"

class ScrapePageService


  def self.get_agent_object(read_timeout, open_timeout, idle_timeout)
    agent = Mechanize.new
    agent.read_timeout = read_timeout
    agent.open_timeout = open_timeout
    agent.keep_alive = false
    agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
    agent.idle_timeout = idle_timeout
    agent.pluggable_parser.default = Mechanize::Page
    agent
  end
  
  def self.set_agent_proxy(agent, ip, port, username, password)
    @agents = File.readlines("user_agents.txt")
    agent.user_agent =  @agents.sample.strip
    agent.set_proxy(ip, port, username, password)
  end


  def self.send_request(**kwargs)
    agent = get_agent_object(kwargs[:read_timeout], kwargs[:open_timeout], kwargs[:idle_timeout])
    tries = 0
    max_tries = kwargs[:max_retries]
    set_agent_proxy(agent, kwargs[:ip], kwargs[:port], kwargs[:username], kwargs[:password])
    begin
      puts "Start request #{Time.now}"
      puts "Url is: #{kwargs[:url]}"
      page = kwargs[:params].nil? ? agent.get(kwargs[:url], nil, kwargs[:headers]) : agent.post(kwargs[:url], kwargs[:params], kwargs[:headers])
      puts "End request #{Time.now}"
      puts "Found"
    rescue Mechanize::ResponseCodeError => ex
      puts "Response error: HTTP #{ex.response_code}, proxy: #{agent.proxy_addr}, End Request: #{Time.now}"
      refresh_agent(agent)
      set_agent_proxy(agent, kwargs[:ip], kwargs[:port], kwargs[:username], kwargs[:password])
      tries += 1
      retry if tries < max_tries
    rescue Exception => ex
      puts "Message: #{ex.message}, proxy: #{agent.proxy_addr}, End Request: #{Time.now}"
      refresh_agent(agent)
      set_agent_proxy(agent, kwargs[:ip], kwargs[:port], kwargs[:username], kwargs[:password])
      if (ex.message.include?("Verify your identity") || ex.message.include?("Robot or human"))
        retry
      else
        tries += 1
        retry if tries < max_tries
      end
    end
    return page
  end

  def self.refresh_agent(agent)
    agent.cookie_jar.clear!
    agent.history.clear
  end


end