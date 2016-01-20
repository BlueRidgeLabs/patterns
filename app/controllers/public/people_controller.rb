class Public::PeopleController < ApplicationController

  # GET /people/new
  def new
    @person = ::Person.new
  end

  # POST /people
  def create
    @person = ::Person.new(person_params)

    respond_to do |format|
      if @person.save
        format.html { redirect_to @person, notice: 'Person was successfully created.' }
      else
        format.html { render action: 'new' }
      end
    end
  end

  private

    def person_params
      params[:person]
    end
end
