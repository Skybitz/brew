# typed: false
# frozen_string_literal: true

require "rubocops/uses_from_macos"

describe RuboCop::Cop::FormulaAudit::ProvidedByMacos do
  subject(:cop) { described_class.new }

  let(:path) { Tap::TAP_DIRECTORY/"homebrew/homebrew-foo" }

  before do
    path.mkpath
    (path/"style_exceptions").mkpath
  end

  def setup_style_exceptions
    (path/"style_exceptions/provided_by_macos_formulae.json").write <<~JSON
      [ "foo", "bar" ]
    JSON
  end

  it "fails for formulae not in provided_by_macos_formulae list" do
    setup_style_exceptions

    expect_offense(<<~RUBY, "#{path}/Formula/baz.rb")
      class Baz < Formula
        url "https://brew.sh/baz-1.0.tgz"
        homepage "https://brew.sh"

        keg_only :provided_by_macos
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Formulae that are `keg_only :provided_by_macos` should be added to `style_exceptions/provided_by_macos_formulae.json`
      end
    RUBY
  end

  it "fails for homebrew-core formulae not in provided_by_macos_formulae list" do
    expect_offense(<<~RUBY, "/homebrew-core/")
      class Baz < Formula
        url "https://brew.sh/baz-1.0.tgz"
        homepage "https://brew.sh"

        keg_only :provided_by_macos
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Formulae in homebrew/core that are `keg_only :provided_by_macos` should be added to the `PROVIDED_BY_MACOS_FORMULAE` list (in the Homebrew/brew repo)
      end
    RUBY
  end

  it "succeeds for formulae in provided_by_macos_formulae list" do
    setup_style_exceptions

    expect_no_offenses(<<~RUBY, "#{path}/Formula/foo.rb")
      class Foo < Formula
        url "https://brew.sh/foo-1.0.tgz"
        homepage "https://brew.sh"

        keg_only :provided_by_macos
      end
    RUBY
  end

  it "succeeds for formulae that are keg_only for a different reason" do
    setup_style_exceptions

    expect_no_offenses(<<~RUBY, "#{path}/Formula/foo.rb")
      class Baz < Formula
        url "https://brew.sh/foo-1.0.tgz"
        homepage "https://brew.sh"

        keg_only :versioned_formula
      end
    RUBY
  end

  include_examples "formulae exist", described_class::PROVIDED_BY_MACOS_FORMULAE
end
