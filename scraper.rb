require 'faraday'
require 'faraday/retry'
require 'byebug'
require 'securerandom'
# get cookie txt file from user
# convert to hash which can be used in faraday
# do initialisation url to get user id
# get company info
# get employee info
# get payroll info
# get paycycle info (not done before)
# cookies remain the same throughout the website, msearch path can be used to get all the info above, just need to change the payload accordingly. 
#  #decrypt_payload("employee-listing",payload[:x],payload[:y],payload[:z])

class Scraper
  @@data_hash = {}
  def scrape_data(filename)
    
    extra_headers = {
      'Accept': 'application/json, text/javascript, */*; q=0.01',
     'Accept-Language': 'en-US,en;q=0.9',
     'Connection': 'keep-alive',
     'Content-Type': 'application/json',
     'Origin': 'https://app.hellohr.co.za',
     'Referer': 'https://app.hellohr.co.za/',
     'Sec-Fetch-Dest': 'empty',
     'Sec-Fetch-Mode': 'cors',
     'Sec-Fetch-Site': 'same-origin',
     'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36',
     'X-Bubble-Breaking-Revision': '5',
     'X-Bubble-Epoch-ID': '1664187070220x898884467470903200',
     'X-Bubble-Epoch-Name': 'Epoch:Runmode page fully loaded',
     'X-Bubble-Fiber-ID': '1664187071888x962681380245390800',
     'X-Bubble-PL': '1664187070618x16416',
     'X-Bubble-R': 'https://app.hellohr.co.za/',
     'X-Bubble-UTM-Data': '{}',
     'X-Requested-With': 'XMLHttpRequest',
     'cache-control': 'no-cache',
     'sec-ch-ua': '"Google Chrome";v="105", "Not)A;Brand";v="8", "Chromium";v="105"',
     'sec-ch-ua-mobile': '?0',
     'sec-ch-ua-platform': '"Windows"',
    }
    context = "employee-listing"
    
    # import file
    cookies = File.readlines("/home/tauhir/hello_hr/hellohr.co.za_cookies.txt",chomp: true).map {|line| line.split("\t")}
    cookies = cookies.slice(4,cookies.size-4) #ignore first 4 lines
    cookies = cookies.map {|line| line.slice(5,2)}.to_h
    cookies.delete('first_session')
    cookies.delete('_fw_crm_v') # these two cookies cause issues, they're not included in the requests
    cookies = cookies.map {|h| h.join '=' }.join(';')
    cook = "_ga=GA1.1.496444998.1664184067; _hjSessionUser_1859309=eyJpZCI6ImU2MTlhMjRmLWU3NTMtNTk2OC1hMWE2LTdhMjMyN2Y0NGIzMyIsImNyZWF0ZWQiOjE2NjQxODQwNjY4MjcsImV4aXN0aW5nIjp0cnVlfQ==; joe-chnlcustid=0320c6fd-7d0a-41ef-8fe3-046584519e75; spd-custhash=a102eefe89e5cbc79f12098685795739a3bab1eb; employee-listing_live_u2main=1664780285681x371563801862858200; employee-listing_live_u2main.sig=1rRws_IUeSmOwkPmAA3QJUJ22Aw; employee-listing_u1main=1663326026672x619453597084089700; _hjIncludedInSessionSample=0; _hjSession_1859309=eyJpZCI6IjBkMzkzMTk0LTA3Y2QtNDkxOC1hOWRmLTBkZDBjYWNlYmZhZCIsImNyZWF0ZWQiOjE2NjQ3OTc2NzkzODYsImluU2FtcGxlIjpmYWxzZX0=; _hjIncludedInPageviewSample=1; _hjAbsoluteSessionInProgress=1; _ga_BH21BD7T9L=GS1.1.1664797677.37.1.1664797910.0.0.0"
    #byebug
    extra_headers['Cookie'] = cookies
    # use the init url to get the user_id used as a key in the payloads
    init_url = "https://app.hellohr.co.za/api/1.1/init/data?location=https%3A%2F%2Fapp.hellohr.co.za%2F"
    resp = Faraday.get(init_url) do |req|
      req.headers['Cookie'] = cookies
    end
    response_data = JSON.parse(resp.body)[0]
    account_id = response_data["data"]["account_custom_account"]
    user_id = response_data["data"]["Created By"] #concern is that this could be a different user but we hope not or we hope they don't care
    # now we need to check how many companies there are with an maggregate search
    
    @@data_hash["config_data"] = {:account_id => account_id,:user_id => user_id}
    # now build the payload and get the company information
    company_count = get_aggregate_companies(extra_headers)
    @@data_hash["config_data"][:company_count] =  company_count
    main_conn = create_main_conn(extra_headers)
    company_data = get_company_data(main_conn, account_id, company_count)
    @@data_hash["company_data"] = company_data
    # now build the employee payload and get the data for each company
    #sample_employee_payload is for The Good Sauce

#for each company, get the ID, get employee data (magg + msearch) and payroll data (magg + msearch) 
    for i in 0..@@data_hash["config_data"][:company_count]
      
      this_company_hash = @@data_hash["company_data"][i]
      id = this_company_hash["company_info"]["_id"]
      employees_count = get_aggregate_employees(extra_headers, id)
      byebug
    end

  end

  private

  def get_aggregate_companies(headers)
    payload = build_aggregate_payload(scope = "companies")
    agg_conn = Faraday.new(
      url: "https://app.hellohr.co.za/elasticsearch/maggregate",
      headers: headers
    )
    response = agg_conn.post('post',payload.to_json, headers)
    JSON.parse(response.body)["responses"][0]['count']
  end

  def get_aggregate_employees(headers,id)
    payload = build_aggregate_payload(scope = "employees",id = id)
    agg_conn = Faraday.new(
      url: "https://app.hellohr.co.za/elasticsearch/maggregate",
      headers: headers
    )
    response = agg_conn.post('post',payload.to_json, headers)
    JSON.parse(response.body)["responses"][0]['count']
    # now need to get employees and payroll
  end


  def create_main_conn(headers)
    main_conn = Faraday.new(
      url: 'https://app.hellohr.co.za/elasticsearch/msearch',
      headers: headers
    )
  end

  def get_company_data(connection, account, company_count)
    payload = build_company_payload(account,company_count)
    response = connection.post('post',payload.to_json) # this works
    response = JSON.parse(response.body)["responses"]
    # response format is a bit weird, see sample_company_response.json
    # first company is in ["responses"][0]["hits"]["hits"]
    # the rest are in ["responses"][1]["hits"]["hits"]
    company_array = []
    for i in 0..(company_count-1)
      company_hash = {"company_info":{},"company_name":"","employees":[{"employeeInfo":{},"payrollData":[]}]}
      company_hash["company_info"] = i < 1 ? response[0]["hits"]["hits"][0]["_source"] : response[1]["hits"]["hits"][i-1]["_source"]
      company_hash["company_name"] = company_hash["company_info"]["company_name_text"]
      company_array.append(company_hash)
   end
   company_array
  end

  def build_aggregate_payload(scope, id = nil)
    account = @@data_hash["config_data"][:account_id]
    user = @@data_hash["config_data"][:user_id]
    hash = {}

    case scope
    when "companies"
      hash = 
      {
        "appname"=>"employee-listing",
        "app_version"=>"live",
        "aggregates"=>[{
            "appname"=>"employee-listing",
            "app_version"=>"live",
            "type"=>"custom.company",
            "constraints"=>[{"key"=>"account_custom_account",
            "value"=>"1348695171700984260__LOOKUP__1663328248371x393063430788218900",
            "constraint_type"=>"equals"}],
            "aggregate"=>{
                "fns"=>[{"n"=>"count"}]},
            "search_path"=>"{\"constructor_name\":\"DataSource\",
            \"args\":[{\"type\":\"json\",
            \"value\":\"%p3.bTIiq1.%el.bTJkq.%el.bTKIx0.%el.bTKMa0.%p.%ds\"},
            {\"type\":\"node\",
            \"value\":{\"constructor_name\":\"Element\",
            \"args\":[{\"type\":\"json\",
            \"value\":\"%p3.bTIiq1.%el.bTJkq.%el.bTKIx0.%el.bTKMa0\"}]}},
            {\"type\":\"raw\",
            \"value\":\"Search\"}]}"},
            {"appname"=>"employee-listing",
            "app_version"=>"live",
            "type"=>"custom.company",
            "constraints"=>[{"key"=>"account_custom_account",
            "value"=>"1348695171700984260__LOOKUP__1663328248371x393063430788218900",
            "constraint_type"=>"equals"},
            {"key"=>"restricted_users_list_user",
            "value"=>"1348695171700984260__LOOKUP__1663326026672x619453597084089700",
            "constraint_type"=>"not contains"},
            {"key"=>"restricted_users_list_user",
            "value"=>"1348695171700984260__LOOKUP__1663326026672x619453597084089700",
            "constraint_type"=>"not contains"}],
            "aggregate"=>{"fns"=>[{"n"=>"count"}]},
            "search_path"=>"{\"constructor_name\":\"DataSource\",
            \"args\":[{\"type\":\"json\",
            \"value\":\"%p3.bTIiq1.%el.bTJkq.%el.bTOPR0.%el.bTQjf.%p.%ds\"},
            {\"type\":\"node\",
            \"value\":{\"constructor_name\":\"Element\",
            \"args\":[{\"type\":\"json\",
            \"value\":\"%p3.bTIiq1.%el.bTJkq.%el.bTOPR0.%el.bTQjf\"}]}},
            {\"type\":\"raw\",
            \"value\":\"Search\"}]}"}]
        }
  
        hash["aggregates"][0]["constraints"][0]["value"] = account
        hash["aggregates"][1]["constraints"][0]["value"] = account
        hash["aggregates"][1]["constraints"][1]["value"] = user
        hash["aggregates"][1]["constraints"][2]["value"] = user
    when "employees"
      hash = 
      {
        "appname": "employee-listing",
        "app_version": "live",
        "aggregates": [
          {
            "appname": "employee-listing",
            "app_version": "live",
            "type": "user",
            "constraints": [
              {
                "key": "_id",
                "constraint_type": "not equal",
                "value": "admin_user"
              },
              {
                "key": "_id",
                "constraint_type": "not equal",
                "value": "admin_user_employee-listing_live"
              },
              {
                "key": "_id",
                "constraint_type": "not equal",
                "value": "admin_user_employee-listing_live"
              },
              {
                "key": "_id",
                "constraint_type": "not equal",
                "value": "admin_user_employee-listing_test"
              },
              {
                "key": "company1_custom_company",
                "value": "1348695171700984260__LOOKUP__1664272257316x854080539290239000",
                "constraint_type": "equals"
              },
              {
                "key": "user_signed_up",
                "constraint_type": "equals",
                "value": true
              }
            ],
            "aggregate": {
              "fns": [
                {
                  "n": "count"
                }
              ]
            },
            "search_path": "{\"constructor_name\":\"DataSource\",\"args\":[{\"type\":\"json\",\"value\":\"%p3.bTMnU.%el.bTJkq.%el.bTKrX1.%el.cmSXF.%el.cmSXM.%p.%ds\"},{\"type\":\"node\",\"value\":{\"constructor_name\":\"Element\",\"args\":[{\"type\":\"json\",\"value\":\"%p3.bTMnU.%el.bTJkq.%el.bTKrX1.%el.cmSXF.%el.cmSXM\"}]}},{\"type\":\"raw\",\"value\":\"Search\"}]}"
          }
        ]
      }
      if hash[:aggregates][0][:constraints][4][:key] == "company1_custom_company"
        # value takes the format of "{{user_id}}__LOOKUP__{{company_id}} e.g"1348695171700984260__LOOKUP__1664272257316x854080539290239000"
        user_id = user.split("__")[0]
        hash[:aggregates][0][:constraints][4][:value] = "#{user_id}__LOOKUP__#{id}"
      else
        puts "building employee maggregate payload failed"
      end
    else
      puts "provide scope"
    end

    encrypt_payload('employee-listing',hash)
  end

  def build_company_payload(user_id,company_count)
    working_hash = {
      "appname"=>"employee-listing",
      "app_version"=>"live",
      "searches"=>[]
    }
    company_hash = {
      "appname"=>"employee-listing",
      "app_version"=>"live",
      "type"=>"custom.company",
      "constraints"=>[{
          "key"=>"account_custom_account",
          "value"=>user_id,
          "constraint_type"=>"equals"}],
      "sorts_list"=>[],
      "from"=>0,
      "n"=>1,
      "search_path"=>"{\"constructor_name\":\"DataSource\",\"args\":[{\"type\":\"json\",\"value\":\"%p3.bTIiq1.%el.bTJkq.%el.bTOPR0.%el.bTQjf.%p.%ds\"},{\"type\":\"node\",\"value\":{\"constructor_name\":\"Element\",\"args\":[{\"type\":\"json\",\"value\":\"%p3.bTIiq1.%el.bTJkq.%el.bTOPR0.%el.bTQjf\"}]}},{\"type\":\"raw\",\"value\":\"Search\"}]}"
    }
    final_hash = []
    this_hash = company_hash.clone
    this_hash["from"] = company_count-1
    this_hash["n"] = 1
    final_hash.append(this_hash)

    if company_count > 1
      this_hash = company_hash.clone
      this_hash["from"] = 0
      this_hash["n"] = company_count-1
      final_hash.append(this_hash) 
    end

    this_hash = company_hash.clone
    this_hash["from"] = company_count > 1 ? company_count : 0
    this_hash["n"] = 10-company_count
    final_hash.append(this_hash)
    working_hash["searches"] = final_hash
    encrypt_payload('employee-listing',working_hash)
  end

  def decrypt_payload(context, x, y, z)
    decrypt = ->(e, t, r, data) {
      cipher = OpenSSL::Cipher.new('AES-256-CBC')
      cipher.decrypt
      cipher.key = OpenSSL::KDF.pbkdf2_hmac(e, salt: r, iterations: 7, length: 32, hash: "md5")
      cipher.iv  = OpenSSL::KDF.pbkdf2_hmac(t, salt: r, iterations: 7, length: 16, hash: "md5")
      cipher.update(Base64.decode64(data)) + cipher.final
    }
    r = decrypt[context, "po9", context, y]
    n = r.split('_').first
    o = decrypt[context, "fl1", context, x]
    i = "#{context}#{n}"
    JSON.parse(decrypt[i, o, context, z])
  end

  def encrypt_payload(context, data)
    encrypt = ->(e, t, r, data) {
      cipher = OpenSSL::Cipher.new('AES-256-CBC')
      cipher.encrypt
      cipher.key = OpenSSL::KDF.pbkdf2_hmac(e, salt: r, iterations: 7, length: 32, hash: "md5")
      cipher.iv  = OpenSSL::KDF.pbkdf2_hmac(t, salt: r, iterations: 7, length: 16, hash: "md5")
      Base64.encode64(cipher.update(data) + cipher.final).strip
    }
    n = (Time.now.to_f * 1000).to_i.to_s
    o = SecureRandom.random_number().to_s
    {
      x: encrypt[context, 'fl1', context, o],
      y: encrypt[context, 'po9', context, "#{n}_1"],
      z: encrypt["#{context}#{n}", o, context, data.to_json],
    }
  end
end
  
  
  # now build the payload and get the company information
  if ARGV[0] != nil
    scraper = Scraper.new
    scraper.scrape_data(ARGV[0])
  else 
    puts "try again with file argument"
  end