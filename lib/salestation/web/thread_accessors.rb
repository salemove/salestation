module Salestation
  module ThreadAccessors
    # thread_mattr_reader + thread_mattr_writer implementation from activesupport.
    # See https://apidock.com/rails/v5.0.0.1/Module/thread_mattr_reader,
    # https://apidock.com/rails/v5.0.0.1/Module/thread_mattr_writer

    def thread_mattr_reader(*syms)
      syms.each do |sym|
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def self.#{sym}
            Thread.current[:"attr_#{name}_#{sym}"]
          end
        EOS

        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def #{sym}
            Thread.current[:"attr_#{name}_#{sym}"]
          end
        EOS
      end
    end

    def thread_mattr_writer(*syms)
      syms.each do |sym|
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def self.#{sym}=(obj)
            Thread.current[:"attr_#{name}_#{sym}"] = obj
          end
        EOS
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def #{sym}=(obj)
            Thread.current[:"attr_#{name}_#{sym}"] = obj
          end
        EOS
      end
    end

    def thread_mattr_accessor(*syms)
      thread_mattr_reader(*syms)
      thread_mattr_writer(*syms)
    end
  end
end
