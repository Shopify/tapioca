# typed: __STDLIB_INTERNAL

module Open3
  private

  def capture2(*cmd); end
  def capture2e(*cmd); end
  def capture3(*cmd); end
  def pipeline(*cmds); end
  def pipeline_r(*cmds, &block); end
  def pipeline_run(cmds, pipeline_opts, child_io, parent_io); end
  def pipeline_rw(*cmds, &block); end
  def pipeline_start(*cmds, &block); end
  def pipeline_w(*cmds, &block); end
  def popen2(*cmd, &block); end
  def popen2e(*cmd, &block); end
  def popen3(*cmd, &block); end
  def popen_run(cmd, opts, child_io, parent_io); end

  class << self
    def capture2(*cmd); end
    def capture2e(*cmd); end
    def capture3(*cmd); end
    def pipeline(*cmds); end
    def pipeline_r(*cmds, &block); end
    def pipeline_rw(*cmds, &block); end
    def pipeline_start(*cmds, &block); end
    def pipeline_w(*cmds, &block); end
    def popen2(*cmd, &block); end
    def popen2e(*cmd, &block); end
    def popen3(*cmd, &block); end

    private

    def pipeline_run(cmds, pipeline_opts, child_io, parent_io); end
    def popen_run(cmd, opts, child_io, parent_io); end
  end
end
