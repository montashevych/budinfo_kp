class ContactsController < ApplicationController
  allow_unauthenticated_access

  def new
  end

  def create
    redirect_to new_contact_path, notice: t("contacts.stub_submitted")
  end
end
