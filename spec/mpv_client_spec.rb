# frozen_string_literal: true

require "spec_helper"

describe MPV::Client do
  before(:each) do
    @session = test_instance
    @mpv = @session.client
  end

  after(:each) do
    @mpv.command("quit")
  end

  it "can query properties" do
    result = @mpv.get_property("volume")
    expect(result).to be_success
    expect(result.data).to eql(100.0)
  end

  it "can set properties" do
    result = @mpv.get_property("volume")
    expect(result).to be_success
    expect(result.data).to eql(100.0)

    result = @mpv.set_property("volume", 50)
    expect(result).to be_success

    result = @mpv.get_property("volume")
    expect(result).to be_success
    expect(result.data).to eql(50.0)
  end

  it "can observe properties" do
    spy = ProcSpy.new
    @mpv.observe_property(:volume, &spy)
    @mpv.set_property(:volume, 10)
    result = spy.wait(runs: 2)
    expect(result.map(&:first).map(&:data)).to eql([100.0, 10.0])
  end

  it "can handle client-message" do
    spy = ProcSpy.new
    m = "cool-message"
    @mpv.register_message_handler(m, &spy)
    @mpv.command("script-message", m, "a", "b")
    @mpv.command("script-message", m, "c", "d")
    result = spy.wait(runs: 2)
    expect(result).to eql([%w[a b], %w[c d]])
  end

  it "can register a binding" do
    spy = ProcSpy.new
    section = @mpv.register_keybindings(%w[b c d], &spy)
    @mpv.command("keypress", "g")
    @mpv.command("keypress", "c")
    expect(spy.wait.map(&:first).map(&:key)).to eql(%w[c])

    @mpv.unregister_keybindings(section)
    @mpv.command("keypress", "b")
    expect(spy.wait(timeout: 0.5).size).to eql(0)
  end

  it "can connect through inherited file descriptor" do
    script = File.expand_path("fd_test.run", __dir__)
    command = [
      "mpv",
      "--no-config",
      "--idle",
      "--really-quiet",
      "--script=#{script}",
    ].join(" ")
    expect(`#{command}`.strip).to eql("100.0")
  end
end