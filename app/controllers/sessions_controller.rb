class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:create, :failure]

  def create
    auth = request.env['omniauth.auth']
    email = auth.info.email

    # AC-01.2: Deny non-TAMU emails with an explicit error message
    unless email.to_s.downcase.end_with?('@tamu.edu')
      redirect_to root_path, alert: 'Access denied: You must use an official @tamu.edu email address.'
      return
    end

    user = User.from_google(
      email: email,
      full_name: auth.info.name,
      uid: auth.uid,
      provider: auth.provider
    )

    if user&.persisted?
      session[:user_id] = user.id # AC-03.1 & AC-03.4: Maintain logged-in session
      redirect_to dashboard_path, notice: 'Successfully signed in!' # AC-01.3
    else
      redirect_to root_path, alert: 'Failed to sign in using Google.'
    end
  end

  # AC-03.2: Log out and terminate session
  def destroy
    reset_session
    redirect_to root_path, notice: 'Logged out successfully.'
  end

  # AC-01.5: Return user to login on OAuth cancellation without creating partial account
  def failure
    redirect_to root_path, alert: 'Sign-in was canceled or failed. Please try again.'
  end
end
