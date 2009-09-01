require File.join(File.dirname(__FILE__), "test_helper")

class TestMonk < Test::Unit::TestCase
  context "monk init NAME" do
    should "fail if the target working directory is not empty" do
      chdir tmp_path do
        rm_rf("monk-test")
        mkdir("monk-test")

        chdir("monk-test") do
          touch("foobar")
        end

        out, err = monk("init monk-test")
        assert_match /error/, out
      end
    end

    should "create a skeleton app in the target directory" do
      chdir tmp_path do
        rm_rf("monk-test")

        out, err = monk("init monk-test")
        assert_match /initialized.* monk-test/, out
        assert is_template?("monk-test", "default")
      end
    end
  end

  context "monk init" do
    should "fail if the current working directory is not empty" do
      chdir tmp_path do
        rm_rf("monk-test")
        mkdir("monk-test")


        chdir("monk-test") do
          touch("foobar")
          out, err = monk("init")
          assert_match /error/, out
        end
      end
    end

    should "create a skeleton app in the working directory" do
      chdir tmp_path do
        rm_rf("monk-test")
        mkdir("monk-test")

        chdir("monk-test") do
          out, err = monk("init")
          assert_match /initialized/, out
          assert is_template?(".", "default") 
        end
      end
    end

    should "use an alternative skeleton if the option is provided" do
      chdir tmp_path do
        rm_rf("monk-test")
        mkdir("monk-test")

        create_template "foobar"

        chdir("monk-test") do
          out, err = monk("init -s foobar")
          assert_match /initialized/, out
          assert is_template?(".", "foobar") 
        end
      end
    end
  end

  context "monk show NAME" do
    should "display the repository for NAME" do
      out, err = monk("show default")
      assert out[template_path "default"]
    end

    should "display nothing if NAME is not set" do
      out, err = monk("show foobar")
      assert out["repository not found"]
    end
  end

  context "monk list" do
    should "display the configured repositories" do
      out, err = monk("list")
      assert out["default"]
      assert out[template_path "default"]
    end
  end

  context "monk add NAME REPOSITORY" do
    should "add the named repository to the configuration" do
      monk("add foobar git://github.com/monkrb/foo.git")
      out, err = monk("show foobar")
      assert out["foobar"]
      assert out["git://github.com/monkrb/foo.git"]
      monk("rm foobar")
    end

    should "allow to fetch from the added repository when using the skeleton parameter" do
      path = create_template "foo"

      chdir(tmp_path) do
        rm_rf("monk-test")
        mkdir("monk-test")

        out, err = monk("init monk-test --skeleton foo")
        assert_match /initialized/, out
        assert_match /#{path}/, out
        assert is_template?("monk-test", "foo") 
      end
    end

    should "allow to fetch from the added repository when using the s parameter" do
      path = create_template "foo"

      chdir(tmp_path) do
        rm_rf("monk-test")
        mkdir("monk-test")

        out, err = monk("init monk-test -s foo")
        assert_match /initialized/, out
        assert_match /#{path}/, out
        assert is_template?("monk-test", "foo") 
      end
    end
  end

  context "monk rm NAME" do
    should "remove the named repository from the configuration" do
      monk("add foobar git://github.com/monkrb/foo.git")
      monk("rm foobar")
      out, err = monk("show foobar")
      assert out["repository not found"]
    end
  end
end
