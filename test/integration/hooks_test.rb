require "integration_test_helper"

module BigTuna
  class Hooks::NoConfig
    NAME = "no_config"
  end
end

class HooksTest < ActionController::IntegrationTest
  def setup
    super
    `cd test/files; mkdir repo; cd repo; git init; echo "my file" > file; git add file; git commit -m "my file added"`
  end

  def teardown
    FileUtils.rm_rf("test/files/repo")
    super
  end

  test "hooks config renders hook config partial if it's present" do
    project = project_with_steps({
      :name => "Koss",
      :vcs_source => "test/files/repo",
      :max_builds => 2,
      :hooks => {"mailer" => "mailer"},
    }, "ls")
    visit edit_project_path(project)
    within("#hook_mailer") do
      click_link "Configure"
    end
    assert page.has_content?("Recipients")
    assert page.has_field?("Build still fails")
    assert page.has_xpath?("//*[@name='hooks_enabled[build_still_fails]' and @checked='checked']")
    uncheck "Build still fails"
    click_button "Edit"
    assert ! page.has_xpath?("//*[@name='hooks_enabled[build_still_fails]' and @checked='checked']")
  end

  test "hooks with no config work as usually" do
    with_hook_enabled(BigTuna::Hooks::NoConfig) do
      project = project_with_steps({
        :name => "Koss",
        :vcs_source => "test/files/repo",
        :max_builds => 2,
        :hooks => {"no_config" => "no_config"},
      }, "ls")
      visit edit_project_path(project)
      within("#hook_no_config") do
        click_link "Configure"
      end
      assert_status_code 200
    end
  end

  test "xmpp hook has a valid configuration form" do
    project = project_with_steps({
      :name => "Koss",
      :vcs_source => "test/files/repo",
      :max_builds => 2,
      :hooks => {"xmpp" => "xmpp"},
    }, "ls")

    visit edit_project_path(project)
    within("#hook_xmpp") do
      click_link "Configure"
    end
    assert page.has_field?("configuration_sender_full_jid")
    assert page.has_field?("configuration_sender_password")
    assert page.has_field?("configuration_recipients")
    click_button "Edit"
    assert_status_code 200
  end
end
