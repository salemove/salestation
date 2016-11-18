class HookMock
  def initialize
    @listeners = []
  end

  def start_listening(&listener)
    @listeners.push(listener)
  end

  def initialize_hook
  end

  def trigger(payload)
    @listeners.each { |listener| listener.call(payload) }
  end
end
