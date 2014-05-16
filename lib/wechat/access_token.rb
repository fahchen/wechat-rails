module Wechat
  class AccessToken
    attr_reader :client, :appid, :secret, :token_storage, :token_data

    def initialize(client, appid, secret, token_storage)
      @appid = appid
      @secret = secret
      @client = client
      @token_storage = token_storage
    end

    def token
      begin
        @token_data ||= if token_file?
                          JSON.parse(File.read(token_storage))
                        else
                          if @token_storage.get_token.blank?
                            self.refresh
                          else
                            { 'access_token' => @token_storage.get_token }
                          end
                        end
      rescue
        self.refresh
      end
      return valid_token(@token_data)
    end

    def refresh
      data = client.get("token", params:{grant_type: "client_credential", appid: appid, secret: secret})
      if valid_token(data)
        if token_file?
          File.open(token_storage, 'w'){|f| f.write(data.to_s)}
        else
          @token_storage.update_token data["access_token"]
        end
      end
      return @token_data = data
    end

    private
    def valid_token token_data
      access_token = token_data["access_token"]
      raise "Response didn't have access_token" if  access_token.blank?
      return access_token
    end

    def token_file?
      !@token_storage.respond_to?(:update_token)
    end

  end
end
