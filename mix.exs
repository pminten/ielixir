defmodule Ielixir.Mixfile do
  use Mix.Project

  def project do
    [ app: :ielixir,
      version: "0.0.1",
      elixir: "~> 0.12.5-dev",
      elixirc_options: elixirc_options(Mix.env),
      deps: deps,
      escript_main_module: IElixir ]
  end

  def elixirc_options(env) when env in [:dev, :test] do
    [exlager_level: :debug]
  end

  def elixirc_options(env) when env in [:prod] do
    [exlager_level: :warning]
  end

  # Configuration for the OTP application
  def application do
    [mod: { IElixir, [ {:connection_file, "fake_conn_file"} ] },
     applications: [:crypto, :exlager, :lager],
     env: [
       lager: [
         error_logger_redirect: false,
         crash_log: "/tmp/crash.log"
       ]
     ]]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, git: "https://github.com/elixir-lang/foobar.git", tag: "0.1" }
  #
  # To specify particular versions, regardless of the tag, do:
  # { :barbat, "~> 0.1", github: "elixir-lang/barbat" }
  defp deps do
    [ { :erlzmq, github: "zeromq/erlzmq2" },
      { :json, github: "cblage/elixir-json" },
      { :exlager, github: "khia/exlager" },
      { :uuid, github: "okeuday/uuid" } ]
  end
end
