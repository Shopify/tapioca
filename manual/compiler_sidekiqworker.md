## SidekiqWorker

`Tapioca::Compilers::Dsl::SidekiqWorker` generates RBI files classes that include
[`Sidekiq::Worker`](https://github.com/mperham/sidekiq/wiki/Getting-Started).

For example, with the following class that includes `Sidekiq::Worker`:

~~~rb
class NotifierWorker
  include Sidekiq::Worker
  def perform(customer_id)
    # ...
  end
end
~~~

this compiler will produce the RBI file `notifier_worker.rbi` with the following content:

~~~rbi
# notifier_worker.rbi
# typed: true
class NotifierWorker
  sig { params(customer_id: T.untyped).returns(String) }
  def self.perform_async(customer_id); end

  sig { params(interval: T.any(DateTime, Time), customer_id: T.untyped).returns(String) }
  def self.perform_at(interval, customer_id); end

  sig { params(interval: Numeric, customer_id: T.untyped).returns(String) }
  def self.perform_in(interval, customer_id); end
end
~~~
