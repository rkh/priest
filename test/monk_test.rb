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
    
    should "not remove .git if keep-remote option is passed" do
      chdir tmp_path do
        rm_rf("monk-test")

        out, err = monk("init monk-test --keep-remote")
        assert_match /initialized.* monk-test/, out
        assert File.exist?(tmp_path("monk-test", ".git"))
      end
    end
    
    should "remove .git if no-keep-remote option is passed" do
      chdir tmp_path do
        rm_rf("monk-test")

        out, err = monk("init monk-test --no-keep-remote")
        assert_match /initialized.* monk-test/, out
        assert !File.exist?(tmp_path("monk-test", ".git"))
      end
    end

    should "not remove .git if k option is passed" do
      chdir tmp_path do
        rm_rf("monk-test")

        out, err = monk("init monk-test -k")
        assert_match /initialized.* monk-test/, out
        assert File.exist?(tmp_path("monk-test", ".git"))
      end
    end
    
    should "name remote after remote-name parameter" do
      chdir tmp_path do
        rm_rf "monk-test"
        out, err = monk("init monk-test --keep-remote --remote-name foo")
        assert_match /initialized.* monk-test/, out
        chdir("monk-test") { assert %x[git remote show]["foo"] }
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
    
    should "not remove .git if keep-remote option is passed" do
      chdir tmp_path do
        rm_rf("monk-test")
        mkdir("monk-test")
        
        chdir("monk-test") do
          out, err = monk("init --keep-remote")
          assert_match /initialized/, out
          assert File.exist?(".git")
        end
      end
    end
    
    should "remove .git if no-keep-remote option is passed" do
      chdir tmp_path do
        rm_rf("monk-test")
        mkdir("monk-test")
        
        chdir("monk-test") do
          out, err = monk("init --no-keep-remote")
          assert_match /initialized/, out
          assert !File.exist?(".git")
        end
      end
    end
      
    should "not remove .git if k option is passed" do
      chdir tmp_path do
        rm_rf("monk-test")
        mkdir("monk-test")

        chdir("monk-test") do
          out, err = monk("init -k")
          assert_match /initialized/, out
          assert File.exist?(".git")
        end
      end
    end
    
    should "name remote after remote-name parameter" do
      chdir tmp_path do
        rm_rf "monk-test"
        mkdir "monk-test"
        chdir "monk-test" do
          out, err = monk("init --keep-remote --remote-name foo")
          assert_match /initialized/, out
          assert %x[git remote show]["foo"]
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
    
    should "not remove .git if keep-remote option is passed" do
      chdir tmp_path do
        rm_rf("monk-test")
        mkdir("monk-test")        
        create_template "foo", "--keep-remote"
        
        chdir("monk-test") do
          out, err = monk("init --skeleton foo")
          assert_match /initialized/, out
          assert File.exist?(".git")
        end
      end
    end
    
    should "remove .git if no-keep-remote option is passed" do
      chdir tmp_path do
        rm_rf("monk-test")
        mkdir("monk-test")        
        create_template "foo", "--no-keep-remote"
        
        chdir("monk-test") do
          out, err = monk("init --skeleton foo")
          assert_match /initialized/, out
          assert !File.exist?(".git")
        end
      end
    end
      
    should "not remove .git if k option is passed" do
      chdir tmp_path do
        rm_rf("monk-test")
        mkdir("monk-test")        
        create_template "foo", "-k"
        
        chdir("monk-test") do
          out, err = monk("init --skeleton foo")
          assert_match /initialized/, out
          assert File.exist?(".git")
        end
      end
    end
    
    should "name remote after remote-name parameter" do
      chdir tmp_path do
        rm_rf "monk-test"
        create_template "foo", "--keep-remote --remote-name foo"
        out, err = monk("init monk-test --skeleton foo")
        assert_match /initialized.* monk-test/, out
        chdir("monk-test") { assert %x[git remote show]["foo"] }
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
  
  context "monk copy FROM TO" do
    should "copy a template" do 
      chdir tmp_path do
        rm_rf "monk-test"
        monk "copy default foo"
        monk "init monk-test -s foo"
        assert is_template?("monk-test", "default")
      end
    end
  end
  
  context "monk change NAME" do
    should "remove the named repository from the configuration" do
      monk("add foobar git://github.com/monkrb/foo.git --keep-remote")
      out, err = monk("show foobar")
      assert out["keep_remote: true"]
      monk("change foobar --no-keep-remote")
      out, err = monk("show foobar")
      assert out["keep_remote: false"]
    end
  end
  
end
