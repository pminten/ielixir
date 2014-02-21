defmodule Ielixir.Mixfile do
  use Mix.Project

  def project do
    [ app: :ielixir,
      version: "0.0.1",
      elixir: "~> 0.12.5-dev",
      deps: deps,
      escript_main_module: IElixir ]
  end

  # Configuration for the OTP application
  def application do
    [mod: { IElixir, [ {:connection_file, "fake_conn_file"} ] }]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, git: "https://github.com/elixir-lang/foobar.git", tag: "0.1" }
  #
  # To specify particular versions, regardless of the tag, do:
  # { :barbat, "~> 0.1", github: "elixir-lang/barbat" }
  defp deps do
    [ { :erlzmq, github: "zeromq/erlzmq2" },
      { :jsex, github: "talentdeficit/jsex" } ]
  end
end
