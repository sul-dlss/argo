require 'spec_helper'
require 'cancan/matchers'

describe Ability do
  let(:subject) { described_class.new(user) }
  let(:item) { Dor::Item.new(pid: 'x') }

  context 'as an administrator' do
    let(:user) { mock_user(is_admin?: true)}

    it { should be_able_to(:manage, :everything) }
    it { should be_able_to(:manage_item, item) }
    it { should be_able_to(:manage_content, item) }
    it { should be_able_to(:manage_desc_metadata, item) }
    it { should be_able_to(:create, Dor::AdminPolicyObject) }
    it { should be_able_to(:view_metadata, item) }
    it { should be_able_to(:view_content, item) }
  end

  context 'as a manager' do
    let(:user) { mock_user(is_manager?: true)}

    it { should_not be_able_to(:manage, :everything) }
    it { should be_able_to(:manage_item, item) }
    it { should be_able_to(:manage_content, item) }
    it { should be_able_to(:manage_desc_metadata, item) }
    it { should be_able_to(:create, Dor::AdminPolicyObject) }
    it { should be_able_to(:view_metadata, item) }
    it { should be_able_to(:view_content, item) }
  end

  context 'as a viewer' do
    let(:user) { mock_user(is_viewer?: true)}

    it { should_not be_able_to(:manage_item, item) }
    it { should_not be_able_to(:manage_content, item) }
    it { should_not be_able_to(:manage_desc_metadata, item) }
    it { should_not be_able_to(:create, Dor::AdminPolicyObject) }
    it { should be_able_to(:view_metadata, item) }
    it { should be_able_to(:view_content, item) }
  end

  context 'for items without an APO' do
    let(:user) { mock_user }

    it { should_not be_able_to(:manage_item, item) }
    it { should_not be_able_to(:manage_content, item) }
    it { should_not be_able_to(:manage_desc_metadata, item) }
    it { should_not be_able_to(:view_content, item) }
    it { should_not be_able_to(:view_metadata, item) }
  end

  context 'from an APO' do
    let(:item) { Dor::AdminPolicyObject.new(pid: 'apo') }
    let(:user) { mock_user }

    context 'for a user with a privileged role' do
      before do
        allow(user).to receive(:roles).with('apo').and_return(['recognized-and-permitted-role'])
        allow(item).to receive(:can_manage_item?).with(['recognized-and-permitted-role']).and_return(true)
      end

      it { should be_able_to(:manage_item, item) }
    end

    context 'for a user without a role' do
      before do
        allow(user).to receive(:roles).with('apo').and_return(['some-other-role'])
        allow(item).to receive(:can_manage_item?).with(['some-other-role']).and_return(false)
      end

      it { should_not be_able_to(:manage_item, item) }
    end
  end

  context 'with a role assigned by an APO' do
    let(:item) { Dor::Item.new(pid: 'x', admin_policy_object: apo)}
    let(:apo) { Dor::AdminPolicyObject.new(pid: 'apo') }
    let(:ungoverned_item) { Dor::Item.new(pid: 'y') }
    let(:user) { mock_user }

    before do
      allow(user).to receive(:roles).with('apo').and_return(['recognized-and-permitted-role'])
    end

    context 'as a user with a management role for an item' do
      before do
        allow(item).to receive(:can_manage_item?).with(['recognized-and-permitted-role']).and_return(true)
      end

      it { should_not be_able_to(:manage_item, ungoverned_item) }
      it { should be_able_to(:manage_item, item) }
    end

    context 'as a user with a content management role for an item' do
      before do
        allow(item).to receive(:can_manage_content?).with(['recognized-and-permitted-role']).and_return(true)
      end

      it { should_not be_able_to(:manage_content, ungoverned_item) }
      it { should be_able_to(:manage_content, item) }
    end

    context 'as a user with a metadata management role for an item' do
      before do
        allow(item).to receive(:can_manage_desc_metadata?).with(['recognized-and-permitted-role']).and_return(true)
      end

      it { should_not be_able_to(:manage_desc_metadata, ungoverned_item) }
      it { should be_able_to(:manage_desc_metadata, item) }
    end

    context 'as a user with a content viewer role for an item' do
      before do
        allow(item).to receive(:can_view_content?).with(['recognized-and-permitted-role']).and_return(true)
      end

      it { should_not be_able_to(:view_content, ungoverned_item) }
      it { should be_able_to(:view_content, item) }
    end

    context 'as a user with a metadata viewer role for an item' do
      before do
        allow(item).to receive(:can_view_metadata?).with(['recognized-and-permitted-role']).and_return(true)
      end

      it { should_not be_able_to(:view_metadata, ungoverned_item) }
      it { should be_able_to(:view_metadata, item) }
    end
  end

  context 'without a role assigned by an APO' do
    let(:item) { Dor::Item.new(pid: 'x', admin_policy_object: apo)}
    let(:apo) { Dor::AdminPolicyObject.new(pid: 'apo') }
    let(:user) { mock_user }

    before do
      allow(user).to receive(:roles).with('apo').and_return(['some-other-role'])
    end

    context 'as a user without a management role for an item' do
      before do
        allow(item).to receive(:can_manage_item?).with(['some-other-role']).and_return(false)
      end

      it { should_not be_able_to(:manage_item, item) }
    end

    context 'as a user without a content management role for an item' do
      before do
        allow(item).to receive(:can_manage_content?).with(['some-other-role']).and_return(false)
      end

      it { should_not be_able_to(:manage_content, item) }
    end

    context 'as a user without a metadata management role for an item' do
      before do
        allow(item).to receive(:can_manage_desc_metadata?).with(['some-other-role']).and_return(false)
      end

      it { should_not be_able_to(:manage_desc_metadata, item) }
    end

    context 'as a user without a content viewer role for an item' do
      before do
        allow(item).to receive(:can_view_content?).with(['some-other-role']).and_return(false)
      end

      it { should_not be_able_to(:view_content, item) }
    end

    context 'as a user without a metadata viewer role for an item' do
      before do
        allow(item).to receive(:can_view_metadata?).with(['some-other-role']).and_return(false)
      end

      it { should_not be_able_to(:view_metadata, item) }
    end
  end
end
