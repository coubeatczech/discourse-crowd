# name: discourse-crowd
# about: Atlassian Crowd Login Provider
# version: 0.1
# author: Robin Ward

require_dependency 'auth/oauth2_authenticator'

gem "omniauth_crowd", "2.2.2"

class CrowdAuthenticator < ::Auth::OAuth2Authenticator
  def register_middleware(omniauth)
    OmniAuth::Strategies::Crowd.class_eval do
      def get_credentials
        OmniAuth::Form.build(:title => (options[:title] || "Crowd Authentication")) do
          text_field 'Login', 'username'
          password_field 'Password', 'password'

          if GlobalSetting.respond_to?(:crowd_custom_html)
            html GlobalSetting.crowd_custom_html
          end
        end.to_response
      end
    end
    omniauth.provider :crowd,
                      :name => 'crowd',
                      :crowd_server_url => GlobalSetting.crowd_server_url,
                      :application_name => GlobalSetting.crowd_application_name,
                      :application_password => GlobalSetting.crowd_application_password
  end

  def after_authenticate(auth)
    result = Auth::Result.new

    crowd_uid = auth[:uid]
    crowd_info = auth[:info]

    result.email_valid = true
    result.user = User.where(username: crowd_uid).first

    if (!result.user)
      result.user = User.new
      result.user.name = crowd_info.name
      result.user.username = crowd_uid
      result.user.email = crowd_info.email
      result.user.save
    end


    result
  end

end

title = GlobalSetting.try(:crowd_title) || "Crowd"
button_title = GlobalSetting.try(:crowd_title) || "with Crowd"

auth_provider :title => button_title,
              :authenticator => CrowdAuthenticator.new('crowd'),
              :message => "Authorizing with #{title} (make sure pop up blockers are not enabled)",
              :frame_width => 600,
              :frame_height => 380,
              :background_color => '#003366'
