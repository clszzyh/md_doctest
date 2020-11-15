defmodule MdDoctest.MixProject do
  use Mix.Project

  @version "VERSION" |> File.read!() |> String.trim()
  @github_url "https://github.com/clszzyh/md_doctest"
  @description "README.md"
               |> File.read!()
               |> String.split("<!-- MDOC -->")
               |> Enum.fetch!(1)
               |> String.trim()

  def project do
    [
      app: :md_doctest,
      description: @description,
      version: @version,
      package: [
        licenses: ["MIT"],
        exclude_patterns: [".DS_Store"],
        links: %{
          "GitHub" => @github_url,
          "Changelog" => @github_url <> "/blob/master/CHANGELOG.md"
        }
      ],
      elixirc_options: [warnings_as_errors: System.get_env("CI") == "true"],
      elixir: "~> 1.11",
      source_url: @github_url,
      homepage_url: @github_url,
      docs: [
        source_ref: "v" <> @version,
        source_url: @github_url,
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"]
      ],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:earmark, "~> 1.4.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      ci: [
        "format --check-formatted",
        "compile --warnings-as-errors --force"
      ]
    ]
  end
end
