# General configuration
config[:domain]                  = 'rubaidh.com'
config[:www_prefix]              = true
config[:cloudfront_distribution] = 'E1STMQ3FOGJ7AN'

# UTM-related bits
config[:default_utm_medium]   = 'website'
config[:default_utm_campaign] = 'Rubaidh'

# Calculated Configuration
config[:hostname]           = config[:www_prefix] ? "www.#{config[:domain]}" : config[:domain]
config[:url]                = "https://#{config[:hostname]}"
config[:email_address]      = "hello@#{config[:domain]}"
config[:default_utm_source] = config[:domain]

# Pages with no layout
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# General configuration
activate :directory_indexes
activate :asset_hash
activate :gzip

activate :external_pipeline,
  name: :gulp,
  command: "./node_modules/gulp/bin/gulp.js #{build? ? 'build' : ''}",
  source: 'intermediate/'

# Reload the browser automatically whenever files change
configure :development do
  activate :livereload
end

# Build-specific configuration
configure :build do
  activate :minify_html
end

activate :s3_sync do |s3|
  s3.bucket = config[:hostname]
  s3.aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
  s3.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
end

activate :cloudfront do |cf|
  cf.access_key_id = ENV['AWS_ACCESS_KEY_ID']
  cf.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
  cf.distribution_id = config[:cloudfront_distribution]
  cf.filter = /\.(html|xml|txt)$/
end

caching_policy 'text/html',       max_age: 0, must_revalidate: true
caching_policy 'application/xml', max_age: 0, must_revalidate: true
caching_policy 'text/plain',      max_age: 0, must_revalidate: true

default_caching_policy max_age: (60 * 60 * 24 * 365)

helpers do
  def mail_to_link(options = {})
    mail_to config[:email_address], config[:email_address], options
  end

  def utm_link_to(title_or_url, url_or_options = nil, options = {}, &block)
    if block_given?
      title   = nil
      url     = title_or_url
      options = url_or_options || {}
    else
      title   = title_or_url
      url     = url_or_options
      options = options
    end

    utm_source   = options.delete(:source) || config[:default_utm_source]
    utm_medium   = options.delete(:medium) || config[:default_utm_medium]
    utm_campaign = options.delete(:campaign) || config[:default_utm_campaign]
    utm_content  = options.delete(:content) || title

    query = {
      utm_source: utm_source,
      utm_medium: utm_medium,
      utm_campaign: utm_campaign,
      utm_content: utm_content
    }.merge(options.delete(:query) || {}).reject { |k, v| v.nil? }

    options = { query: query }.merge(options)

    if block_given?
      link_to url, options, &block
    else
      link_to title, url, options
    end
  end

  def xml_timestamp(dateish = Time.now)
    timestamp = dateish.respond_to?(:strftime) ? dateish : Date.parse(dateish)
    timestamp.strftime('%FT%H:%M:%S%:z') 
  end
end
