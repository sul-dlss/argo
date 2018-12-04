# frozen_string_literal: true

module TestViewHelpers
  extend ActiveSupport::Concern

  included do
    before do
      view.send(:extend, ApoHelper)
      view.send(:extend, ArgoHelper)
      view.send(:extend, WorkflowHelper)
      view.send(:extend, Blacklight::HierarchyHelper)
    end
  end
end
