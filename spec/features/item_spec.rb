RSpec.feature "Item management", type: :feature do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }
  scenario "User creates a new item" do
    visit url_prefix + "/items/new"
    item_traits = attributes_for(:item)
    fill_in "Name", with: item_traits[:name]
    fill_in "Category", with: item_traits[:category]
    select CanonicalItem.last.name, from: "Base Item"
    click_button "Save"

    expect(page.find(".alert")).to have_content "added"
  end

  scenario "User creates a new item with empty attributes" do
    visit url_prefix + "/items/new"
    item_traits = attributes_for(:item)
    click_button "Save"

    expect(page.find(".alert")).to have_content "didn't work"
  end

  scenario "User updates an existing item" do
    item = create(:item)
    visit url_prefix + "/items/#{item.id}/edit"
    fill_in "Category", with: item.category + " new"
    click_button "Save"

    expect(page.find(".alert")).to have_content "updated"
  end

  scenario "User updates an existing item with empty attributes" do
    item = create(:item)
    visit url_prefix + "/items/#{item.id}/edit"
    fill_in "Name", with: ""
    click_button "Save"

    expect(page.find(".alert")).to have_content "didn't work"
  end

  scenario "User can filter the #index by category type" do
    Item.delete_all
    item = create(:item, category: "Diapers")
    item2 = create(:item, category: "Menstrual Products")
    visit url_prefix + "/items"
    select Item.first.category, from: "filters_in_category"
    click_button "Filter"

    expect(page).to have_css("table tbody tr", count: 3)
  end

  scenario "User can filter the #index by canonical item" do
    Item.delete_all
    item = create(:item, canonical_item: CanonicalItem.first)
    item2 = create(:item, canonical_item: CanonicalItem.last)
    visit url_prefix + "/items"
    select CanonicalItem.first.name, from: "filters_by_canonical_item"
    click_button "Filter"
    within "#tbl_items" do
      expect(page).to have_css("tbody tr", count: 1)
    end
  end

  scenario "Filters presented to user are alphabetized by category" do
    Item.delete_all
    item = create(:item, category: "same")
    item2 = create(:item, category: "different")
    expected_order = [item2.category, item.category]
    visit url_prefix + "/items"

    expect(page.all("select#filters_in_category option").map(&:text).select(&:present?)).to eq(expected_order)
    expect(page.all("select#filters_in_category option").map(&:text).select(&:present?)).not_to eq(expected_order.reverse)
  end

  describe "Item Table Tabs >" do
    let(:item_pullups) { create(:item, name: "the most wonderful magical pullups that truly potty train", category: "Magic Toddlers") }
    let(:item_tampons) { create(:item, name: "blackbeard's rugged tampons", category: "Menstrual Products") }
    let(:storage_name) { "the poop catcher warehouse" }
    let(:storage) { create(:storage_location, :with_items, item: item_pullups, item_quantity: num_pullups_in_donation, name: storage_name) }
    let!(:aux_storage) { create(:storage_location, :with_items, item: item_pullups, item_quantity: num_pullups_second_donation, name: "a secret secondary location") }
    let(:num_pullups_in_donation) { 666 }
    let(:num_pullups_second_donation) { 1 }
    let(:num_tampons_in_donation) { 42 }
    let(:num_tampons_second_donation) { 17 }
    let(:donation_tampons) { create(:donation, :with_items, storage_location: storage, item_quantity: num_tampons_in_donation, item: item_tampons) }
    let(:donation_aux_tampons) { create(:donation, :with_items, storage_location: aux_storage, item_quantity: num_tampons_second_donation, item: item_tampons) }
    before do
      storage.intake!(donation_tampons)
      aux_storage.intake!(donation_aux_tampons)
      visit url_prefix + "/items"
    end
    # Consolidated these into one to reduce the setup/teardown
    scenario "Displays items in separate tabs", js: true do
      tab_items_only_text = page.find("table#tbl_items", visible: true).text
      expect(tab_items_only_text).not_to have_content "Quantity"
      expect(tab_items_only_text).to have_content item_pullups.name
      expect(tab_items_only_text).to have_content item_tampons.name

      click_link "Items and Quantity" # href="#sectionB"
      tab_items_and_quantity_text = page.find("table#tbl_items_quantity", visible: true).text
      expect(tab_items_and_quantity_text).to have_content "Quantity"
      expect(tab_items_and_quantity_text).not_to have_content storage_name
      expect(tab_items_and_quantity_text).to have_content num_pullups_in_donation
      expect(tab_items_and_quantity_text).to have_content num_pullups_second_donation
      expect(tab_items_and_quantity_text).to have_content num_tampons_in_donation
      expect(tab_items_and_quantity_text).to have_content num_tampons_second_donation
      expect(tab_items_and_quantity_text).to have_content item_pullups.name
      expect(tab_items_and_quantity_text).to have_content item_tampons.name

      click_link "Items, Quantity, and Location" # href="#sectionC"
      tab_items_quantity_location_text = page.find("table#tbl_items_location", visible: true).text
      expect(tab_items_quantity_location_text).to have_content "Quantity"
      expect(tab_items_quantity_location_text).to have_content storage_name
      expect(tab_items_quantity_location_text).to have_content num_pullups_in_donation
      expect(tab_items_quantity_location_text).to have_content num_pullups_second_donation
      expect(tab_items_quantity_location_text).to have_content num_pullups_in_donation + num_pullups_second_donation
      expect(tab_items_quantity_location_text).to have_content num_tampons_in_donation
      expect(tab_items_quantity_location_text).to have_content num_tampons_second_donation
      expect(tab_items_quantity_location_text).to have_content num_tampons_in_donation + num_tampons_second_donation
      expect(tab_items_quantity_location_text).to have_content item_pullups.name
      expect(tab_items_quantity_location_text).to have_content item_tampons.name
    end
  end
end
