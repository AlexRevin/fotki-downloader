require 'rubygems'
require 'fileutils'
require 'open-uri'
require 'net/http'
require 'net/https'
require 'nokogiri'
require 'optparse'
require 'rexml/document'


opt = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby downloader.rb -u login -p password -d directory"
  opts.on("-u login", String, "Specify the login") do |u|
    opt[:user] = u
  end
  opts.on("-p password", String, "Specify the password") do |p|
    opt[:pass] = p
  end
  opts.on("-d directory", String, "Specify the directory to save images to") do |d|
    opt[:dir] = d
  end
end.parse!


class FotkiLogin
  attr_accessor :url, :path, :cookie, :http

  def initialize()
    @url = "login.fotki.com"
    @path = "/login"

    initial_request
  end

  def send_request(login, password)
    p "Logging in .."
    # POST request -> logging in
    data = 'form_submitted=1&login='+login+ '&password='+password

    headers = {
      'Referer' => 'http://login.fotki.com',
      'Content-Type' => 'application/x-www-form-urlencoded'
    }
    headers['Cookie'] = @cookie unless @cookie.nil?

    resp, data = @http.post(@path, data, headers)
    p "Logged in! " if resp.code == "302"
    return [resp.response['set-cookie'], resp.code]
  end

  private

  def initial_request
    @http = Net::HTTP.new(@url, 80)
    @http.use_ssl = false
    resp, data = @http.get(@path, nil)
    @cookie = resp.response['set-cookie']
  end

end

class FotkiPageFetcher
  attr_accessor :cookie, :user, :domain

  def initialize(cookie, user)
    @cookie = cookie
    @user = user
  end

  def send_request(url = nil)
    p "Fetching page:" + url || "null"
    http = Net::HTTP.new(@domain ||= 'public.fotki.com', 80)
    http.read_timeout = 60
    @headers = {
      'Cookie' => @cookie,
      'Referer' => @domain,
      'Content-Type' => 'text/html'
    }
    r_str = ""
    begin
      http.get2(url || "/" + @user + "/", @headers) do |response|
        response.read_body do |str|
          r_str += str
        end
      end
      return r_str
    rescue
      http.get2(url || "/" + @user + "/", @headers) do |response|
        response.read_body do |str|
          r_str += str
        end
      end
      return r_str
    end
  end
end


class FolderAlbumListFetcher
  attr_accessor :cookie, :user, :list

  def initialize(cookie, user)
    @cookie = cookie
    @user = user
    @list = {}
  end

  def get_list(path=nil)
    pf = FotkiPageFetcher.new(@cookie, @user)
    url = path.nil? ? "/" + @user + "/" : path
    @list[url] = []
    res = Nokogiri::HTML(pf.send_request(url))
    res.css('.fdetail .icon a').each do |link|
      p "Found folder: " + link[:href]
      @list[url + link[:href]] = []
      self.get_list(url + link[:href])
    end

    res.css('.fdetail .album a').each do |l|
      p "Found album: " + l[:href]
      @list[url].push(l[:href])
    end
  end
end

class FotkiPhotoListFetcher
  attr_accessor :cookie, :user, :url, :pf

  def initialize(cookie, user, path=nil)
    @cookie = cookie
    @user = user
    @path = path unless path.nil?

    @pf = FotkiPageFetcher.new(cookie, user)
    @pf.domain = @path unless @path.nil?
  end

  def fetch(url)
    data = @pf.send_request(url + "?cmd=fs_slideshow")
    row = data.split("\n")[4]
    p_urls = self.fetch_xml(URI.unescape(row[7..-3]))
  end

  def fetch_xml(url)
    p "Parsing XML"
    doc = REXML::Document.new(@pf.send_request(url))
    p_urls = []
    doc.elements.each('root/photos/photo/pageLink') do |ele|
      p_urls << ele.text
    end
    p_urls
  end

end

class FotkiOriginalUrlRevealer
  attr_accessor :cookie, :user, :pf

  def initialize(cookie, user)
    @cookie = cookie
    @user = user
    @pf = FotkiPageFetcher.new(cookie, user)
  end

  def reveal(url)
    page = Nokogiri::HTML(pf.send_request(url))
    p "Revealing original image link"
    page.xpath('//li/a[@title="Download original file"]').each do |l|
      p "Image unavailable!!!" if l[:href].nil? || l[:href] == ""
      return l[:href]
    end
  end
end

# getting a logged in cookie
fl = FotkiLogin.new
cookie, code = fl.send_request(opt[:user], opt[:pass])

if code == '302' || code == '200'

  fa = FolderAlbumListFetcher.new(cookie, opt[:user])
  fa.get_list
  folders_albums = fa.list

  fpl = FotkiPhotoListFetcher.new(cookie, opt[:user])

  url_revealer = FotkiOriginalUrlRevealer.new(cookie, opt[:user])
  folders_albums.each_pair do |k, v|
    v.each do |a|
      p_page = fpl.fetch(k + a)
      p "Creating directory"
      dir = (opt[:dir][0..-2]) +k + a
      FileUtils.mkdir_p(dir)
      p_page.each do |p|
        img_url = url_revealer.reveal(p)
        if !img_url.nil? && img_url != ""
          system "wget -o files.log -q -b --directory-prefix=#{dir} #{img_url}"
        end
      end
    end
  end
end
