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
    
    should "be able to pull from skeletons with parameter mirror if original is not available" do
      chdir tmp_path do
        rm_rf "monk-test"
        rm_rf create_template("foo", "--mirror")
        out, err = monk("init monk-test --skeleton foo")
        assert_match /initialized.* monk-test/, out
        assert is_template?("monk-test", "foo")
      end
    end

    should "be able to pull from skeletons with parameter m if original is not available" do
      chdir tmp_path do
        rm_rf "monk-test"
        rm_rf create_template("foo", "-m")
        out, err = monk("init monk-test --skeleton foo")
        assert_match /initialized.* monk-test/, out
        assert is_template?("monk-test", "foo")
      end
    end
    
    should "be able to pull from a url instead of a known skeleton" do
      chdir tmp_path do
        rm_rf "monk-test"
        path = create_template("foo")
        out, err = monk("init monk-test --skeleton #{path}")
        assert_match /initialized.* monk-test/, out
        assert is_template?("monk-test", "foo")
      end
    end
    
    should "respect the branch parameter" do
      chdir tmp_path do
        in_template "foobar" do
          system "git checkout -b foo 1>/dev/null 2>&1 || git checkout foo -q"
          File.open("only_in_branch", "w").close
          system "(git add only_in_branch && git commit -a -m 'added') 1>/dev/null 2>&1"
        end 
        rm_rf "monk-test"
        out, err = monk("init monk-test --skeleton foobar --branch foo")
        assert_match /initialized.* monk-test/, out
        assert is_template?("monk-test", "foobar")
        assert File.exist?(File.join("monk-test", "only_in_branch"))
      end
    end
    
    should "respect the b parameter" do
      chdir tmp_path do
        in_template "foobar" do
          system "git checkout -b foo 1>/dev/null 2>&1 || git checkout foo -q"
          File.open("only_in_branch", "w").close
          system "(git add only_in_branch && git commit -a -m 'added') 1>/dev/null 2>&1"
        end 
        rm_rf "monk-test"
        out, err = monk("init monk-test --skeleton foobar -b foo")
        assert_match /initialized.* monk-test/, out
        assert is_template?("monk-test", "foobar")
        assert File.exist?(File.join("monk-test", "only_in_branch"))
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
    
    should "be able to pull from a url instead of a known skeleton" do
      chdir tmp_path do
        rm_rf "monk-test"
        mkdir "monk-test"
        path = create_template("foo")
        chdir "monk-test" do
          out, err = monk("init --skeleton #{path}")
          assert_match /initialized/, out
          assert is_template?(".", "foo")
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
      assert out["keep-remote"]
      assert !out["no-keep-remote"]
      monk("change foobar --no-keep-remote")
      out, err = monk("show foobar")
      assert out["no-keep-remote"]
    end
  end
  
end
