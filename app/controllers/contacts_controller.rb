class ContactsController < ApplicationController
  allow_unauthenticated_access

  def new
    set_meta_tags title: t("meta.titles.contacts"), description: t("meta.descriptions.contacts")
  end

  def create
    redirect_to new_contact_path, notice: t("contacts.stub_submitted")
  end
end
