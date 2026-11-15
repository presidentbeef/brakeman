class ChatsController < ApplicationController
  def show
    @summary = RubyLLM.chat.ask("Summarize the latest support ticket").content
  end

  def run_command
    system(RubyLLM.chat.ask("Which cleanup command should run?").content)
  end

  def evaluate
    code = RubyLLM.chat.with_instructions("Reply with Ruby only").ask("Tidy the inbox").content
    eval(code)
  end

  def next_action
    send(RubyLLM::Chat.new.ask("Which method should run next?").content)
  end

  def report
    filter = OpenAI::Client.new.chat.completions.create(model: "gpt-5", messages: []).choices.first.message.content
    User.where(filter)
  end

  def reflect
    Anthropic::Client.new.messages.create(model: "claude-sonnet-5-5", max_tokens: 10, messages: []).content.first.text.constantize
  end

  def not_an_llm
    # Only known LLM clients count, not any method named ask
    system(Robot.ask("Which command?").content)
  end
end
