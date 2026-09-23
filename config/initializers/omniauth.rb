# Force OmniAuth to use http://localhost:3000 in development
OmniAuth.config.full_host = "http://localhost:3000" if Rails.env.development?

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"], {
    prompt: "select_account",
    image_aspect_ratio: "square",
    image_size: 50
  }
end

OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
