class EmailLinksController < ApplicationController
  skip_before_action :authenticate_user!
  def new;end

  def create
    @email_link = EmailLink.generate(params[:email])

    if @email_link
      flash[:notice] = "Email sent! Please, check your inbox."
    else
      flash[:alert] = "There was an error, please try again!"
    end
    redirect_to new_magic_link_path
  end

  def validate
    email_link = EmailLink.where(token: params[:token]).where("expires_at > ?", DateTime.now).first

    unless email_link
      flash[:alert] = "Invalid or expired token!"
      redirect_to new_magic_link_path
    end
    flash[:notice] = 'Signed in!'
    sign_in(email_link.user)
    redirect_to root_path
  end
end
