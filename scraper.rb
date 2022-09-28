require 'faraday'
require 'faraday/retry'
# get cookie txt file from user
# convert to hash which can be used in faraday
# do initialisation url to get user id
# get company info
# get employee info
# get payroll info
# get paycycle info (not done before)
# cookies remain the same throughout the website, msearch path can be used to get all the info above, just need to change the payload accordingly. 

aggregate_url = "https://app.hellohr.co.za/elasticsearch/maggregate"
msearch_url = "https://app.hellohr.co.za/elasticsearch/msearch"
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

def main(filename)
  # import file
  cookies = File.readlines("/home/tauhir/hello_hr/hellohr.co.za_cookies.txt",chomp: true).map {|line| line.split("\t")}
  cookies = cookies.slice(4,cookies.size-4) #ignore first 4 lines
  cookies = cookies.map {|line| line.slice(5,2)}.to_h.map {|h| h.join '=' }.join(';')
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
  company_count = get_aggregate_companies(account_id, user_id)

  # now build the payload and get the company information
  main_conn = create_main_conn
  get_company_data(main_conn, account_id, company_count)
end


# now build the payload and get the company information



private

def get_aggregate_companies(account, user)
  payload = build_aggregate_payload(account, user)
  agg_conn = Faraday.new(
    url: aggregate_url,
    headers: extra_headers
  )
  response = main_conn.post('post',payload.to_json, extra_headers)
  JSON.parse(response.body)["responses"][0]['count']
end

def create_main_conn
  main_conn = Faraday.new(
    url: 'https://app.hellohr.co.za/elasticsearch/msearch',
    headers: extra_headers
  )
end

def get_company_data(connection, account, company_count)
  payload = build_company_payload(account,company_count)
  response = connection.post('post',payload.to_json, extra_headers) # this works
  #now work with response and store 3 companies
end

def build_aggregate_payload(account,user)
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
    hash
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
  this_hash = hash.clone
  hash["from"] = count-1
  hash["n"] = 1
  final_hash.append(this_hash)

  if count > 1
    this_hash = hash.clone
    hash["from"] = 0
    hash["n"] = count-1
    final_hash.append(this_hash) 
  end

  this_hash = hash.clone
  hash["from"] = count > 1 ? count : 0
  hash["n"] = 10-count
  final_hash.append(this_hash)
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







  
privat