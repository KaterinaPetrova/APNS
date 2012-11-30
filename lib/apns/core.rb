module APNS
  require 'socket'
  require 'openssl'
  require 'json'

  @port = 2195
  
  class << self
    attr_accessor :port
  end

  def self.host_for_mode(mode)
    mode == :developing ? 'gateway.sandbox.push.apple.com' : 'gateway.push.apple.com'
  end
  
  def self.send_notification(device_token, message, send_options = {})
    n = APNS::Notification.new(device_token, message)
    self.send_notifications([n], send_options)
  end
  
  def self.send_notifications(notifications, send_options)
    sock, ssl = self.open_connection(send_options)
    
    notifications.each do |n|
      ssl.write(n.packaged_notification)
    end
    
    ssl.close
    sock.close
  end
  
  def self.feedback(send_options)
    sock, ssl = self.feedback_connection(send_options)
    
    apns_feedback = []
    
    while line = sock.gets   # Read lines from the socket
      line.strip!
      f = line.unpack('N1n1H140')
      apns_feedback << [Time.at(f[0]), f[2]]
    end
    
    ssl.close
    sock.close
    
    return apns_feedback
  end
  
  protected

  def self.open_connection(send_options)
    raise "The path to your pem file does not exist!" unless File.exist?(send_options[:pem_path])
    
    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(send_options[:pem_path]))
    context.key  = OpenSSL::PKey::RSA.new(File.read(send_options[:pem_path]), send_options[:pass])

    sock         = TCPSocket.new(APNS.host_for_mode(send_options[:mode]), self.port)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock,context)
    ssl.connect

    return sock, ssl
  end
  
  def self.feedback_connection(send_options)
    raise "The path to your pem file does not exist!" unless File.exist?(send_options[:pem_path])
    
    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(send_options[:pem_path]))
    context.key  = OpenSSL::PKey::RSA.new(File.read(send_options[:pem_path]), send_options[:pass])

    fhost = APNS.host_for_mode(send_options[:mode]).gsub('gateway','feedback')
    puts fhost
    
    sock         = TCPSocket.new(fhost, 2196)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock,context)
    ssl.connect

    return sock, ssl
  end
  
end