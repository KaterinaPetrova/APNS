module APNS
  require 'socket'
  require 'openssl'
  require 'json'

  @host = 'gateway.sandbox.push.apple.com'
  @port = 2195
  
  class << self
    attr_accessor :host, :port
  end
  
  def self.send_notification(pem_path, pass, device_token, message)
    n = APNS::Notification.new(device_token, message)
    self.send_notifications(pem_path, pass, [n])
  end
  
  def self.send_notifications(pem_path, pass, notifications)
    sock, ssl = self.open_connection(pem_path, pass)
    
    notifications.each do |n|
      ssl.write(n.packaged_notification)
    end
    
    ssl.close
    sock.close
  end
  
  def self.feedback
    sock, ssl = self.feedback_connection
    
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

  def self.open_connection(pem_path, pass)
    raise "The path to your pem file does not exist!" unless File.exist?(pem_path)
    
    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(pem_path))
    context.key  = OpenSSL::PKey::RSA.new(File.read(pem_path), pass)

    sock         = TCPSocket.new(self.host, self.port)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock,context)
    ssl.connect

    return sock, ssl
  end
  
  def self.feedback_connection(pem_path, pass)
    raise "The path to your pem file does not exist!" unless File.exist?(pem_path)
    
    context      = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(File.read(pem_path))
    context.key  = OpenSSL::PKey::RSA.new(File.read(pem_path), pass)

    fhost = self.host.gsub('gateway','feedback')
    puts fhost
    
    sock         = TCPSocket.new(fhost, 2196)
    ssl          = OpenSSL::SSL::SSLSocket.new(sock,context)
    ssl.connect

    return sock, ssl
  end
  
end
