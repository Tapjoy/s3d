require 'json'

class InvalidConfig < ArgumentError
end

class ConfigFile
  def initialize(name, git_tag=nil, git_sha1=nil, author=nil)
    file = File.read(name)
    @config = JSON.parse(file)

    # set defaults
    @config["aws"] ||= {}
    @config["cdns"] ||= {}

    @config["use_git"] = true if @config["use_git"].nil?

    if @config["upload"]["dir"]
      @config["resource"] = @config["upload"]["dir"]
      @config["command"] = 'sync'
    elsif @config["upload"]["file"]
      @config["resource"] = @config["upload"]["file"]
      @config["command"] = 'cp'
    else
      raise InvalidConfig.new("Must supply either config['upload']['dir'] or config['upload']['file']")
    end

    @config["git_tag"] ||= git_tag unless git_tag.nil?
    @config["git_sha1"] ||= git_sha1 unless git_sha1.nil?
    @config["author"] ||= author unless author.nil?
    
    # require some values or die
    @config["bucket"]["name"] rescue raise InvalidConfig.new("Missing config['bucket']['name']")
  end

  def command
    @config["command"]
  end

  def use_git
    @config["use_git"]
  end

  def upload_dir
    if resource = @config["resource"]
      return "#{project_path}/#{resource}"
    end
  end

  def aws_account
    @config["aws"]["account"]
  end

  def aws_keyfile
    @config["aws"]["keyfile"]
  end

  def bucket_name
    @config["bucket"]["name"]
  end

  def bucket_path
    if path = @config["bucket"]["path"]

      git_tag = @config["git_tag"]
      if (git_tag.nil? || git_tag == '') and use_git
        # Git Repo
        git_tag  = `git describe --abbrev=0 --tags 2>/dev/null`
        git_tag.gsub!("\n", "")
        git_tag  = git_tag != "" ? git_tag : "v0.0.0"
      end

      git_sha1 = @config["git_sha1"]
      if (git_sha1.nil? || git_sha1 == '') and use_git
        git_sha1 = `git rev-parse HEAD | head -c 8`
      end

      author = @config["author"]
      if (author.nil? || author == '')
        author = `whoami`
        author.gsub!("\n", "")
      end

      path_template = path.dup

      if git_tag and git_sha1
        path_template.gsub!("$git_tag", git_tag)
        path_template.gsub!("$git_sha1", git_sha1)
      end

      if author
        path_template.gsub!("$author", author)
      end

      return path_template
    else
      return "/"
    end
  end

  def bucket_options
    @config["bucket"]["options"]
  end

  def cdns
    @config["cdns"]
  end

  private

  def project_path
    if use_git
      `git rev-parse --show-toplevel`.tr("\n", '')
    end
    Dir.pwd
  end
end
  # ----------------------------------


  # def s3_sync_flags
  #   @config["s3-opts"] || ""
  # end

  # def bucket
  #   @config["bucket"]
  # end

  # def deploy_path
  #   # Git Repo
  #   git_tag  = `git describe --abbrev=0 --tags 2>/dev/null`
  #   git_tag  = git_tag != "" ? git_tag : "v0.0.0"
  #   git_sha1 = `git rev-parse HEAD | head -c 8`

  #   path_template = @config["path"].dup

  #   path_template.gsub!("$git_tag", git_tag)
  #   path_template.gsub!("$git_sha1", git_sha1)

  #   return path_template
  # end

  # def build_dir
  #   return "#{project_path}/#{@config["build-dir"]}"
  # end

