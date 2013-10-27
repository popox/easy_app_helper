#-------------------------------------------------------------------------------
#  
#
# Copyright (c) 2013 L.Briais under MIT license
# http://opensource.org/licenses/MIT
#-------------------------------------------------------------------------------

require 'rspec'
require 'easy_app_helper'


#describe EasyAppHelper::Core::Config do
describe EasyAppHelper.config do
  SAMPLE_STRING = 'TestConfig'


  it 'should be fully initialized when first accessed' do
    subject.should_not be nil
    subject.logger.should_not be nil
  end

  it 'should be consistent regarding the way it is accessed' do
    subject[:basic_test] = SAMPLE_STRING
    expect(subject[]).to eq subject.to_hash
    expect(subject[:basic_test]).to eq SAMPLE_STRING
  end


  it 'should be the same object accross different instances' do
    expect(subject[:basic_test]).to eq SAMPLE_STRING
  end

  it 'should store the data in the :modified layer' do
    expect(subject.find_layer :basic_test).to eq :modified
    expect(subject.internal_configs[:modified][:content][:basic_test]).to eq subject[:basic_test]
  end

  it 'should provide a direct r/w access to layers' do
    subject.internal_configs[:system][:content][:stupid_conf] = SAMPLE_STRING
    expect(subject[:stupid_conf]).to eq SAMPLE_STRING
  end

  it 'should be reloaded when :config-file property changes' do
    subject.should_receive(:force_reload)
    subject[:'config-file'] = SAMPLE_STRING
  end

  it 'should be reloaded when script_filename changes' do
    subject.should_receive(:force_reload)
    subject.script_filename = SAMPLE_STRING
  end


  describe 'should override data when present in multiple layers' do
    before(:all) do
      EasyAppHelper.config.layers.each do |layer|
        EasyAppHelper.config.internal_configs[layer][:content][:basic_test] = "#{SAMPLE_STRING} #{layer.to_s}"
      end
      EasyAppHelper.config.internal_configs[:command_line][:content][:'config-file'] = true
    end

    context "when requesting some data" do
      let(:layers) {[:modified, :command_line, :specific_file, :user, :global, :internal, :system]}

      original_ordered_layers = [:modified, :command_line, :specific_file, :user, :global, :internal, :system]
      layers = original_ordered_layers.dup
      original_ordered_layers.each do |layer|
        test_descr = "should find the data in #{layer} layer if present in #{layer} layer"
        unless layers.length == original_ordered_layers.length
          already_removed = original_ordered_layers - layers
          if already_removed.length == 1
            test_descr += " and not present in #{already_removed[0]} layer"
          end
          if already_removed.length > 1
            test_descr += " and not present in #{already_removed.join ', '} layers"
          end
        end

        it test_descr, layers: layers.dup  do
          layers = example.metadata[:layers]
          expect(subject.find_layer :basic_test).to eq layer
          expect(subject[:basic_test]).to eq "#{SAMPLE_STRING} #{layer.to_s}"
          subject.internal_configs[layer][:content].delete :basic_test
        end

        layers.shift

      end
    end

  end

  context "when reset" do

    it "should remove all modifications done the standard way" do
      subject[:test_remove] = SAMPLE_STRING
      subject.reset
      expect(subject[:test_remove]).to be_nil
    end

    it "should keep modifications directly done on internal layers" do
      subject.internal_configs[:system][:content][:stupid_conf] = SAMPLE_STRING
      subject.reset
      expect(subject.internal_configs[:system][:content][:stupid_conf]).to eq SAMPLE_STRING
    end

  end

  context "when reloaded" do

    it "should keep all modifications done the standard way" do
      subject[:test_remove] = SAMPLE_STRING
      subject.load_config
      expect(subject[:test_remove]).to eq SAMPLE_STRING
    end

    it "should remove all modifications directly done on internal layers" do
      subject.internal_configs[:system][:content][:stupid_conf] = SAMPLE_STRING
      subject.internal_configs[:command_line][:content][:stupid_conf] = SAMPLE_STRING
      subject.load_config
      expect(subject.internal_configs[:system][:content][:stupid_conf]).to be_nil
      expect(subject.internal_configs[:command_line][:content][:stupid_conf]).to be_nil
    end

  end

  context "when reloaded (forced)" do

    it "should keep all modifications done the standard way" do
      subject[:test_remove] = SAMPLE_STRING
      subject.force_reload
      expect(subject[:test_remove]).to eq SAMPLE_STRING
    end

    it "should remove all modifications directly done on internal layers" do
      subject.internal_configs[:system][:content][:stupid_conf] = SAMPLE_STRING
      subject.internal_configs[:command_line][:content][:stupid_conf] = SAMPLE_STRING
      subject.force_reload
      expect(subject.internal_configs[:system][:content][:stupid_conf]).to be_nil
      expect(subject.internal_configs[:command_line][:content][:stupid_conf]).to be_nil
    end

  end


  context "When dealing with command line" do

    it 'should have the same content using #command_line_config and #internal_configs[:command_line][:content]' do
      subject.add_command_line_section('Scripts analysis') do |slop|
        slop.on :p, :pipo, 'Directory path where SQL files are located.', argument: false
      end
      expect(subject.command_line_config).to eq subject.internal_configs[:command_line][:content]
    end

  end

end