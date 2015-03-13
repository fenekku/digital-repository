require 'rails_helper'
RSpec.describe GenericFile do

  context 'iif presentation api' do
    require 'iiif/presentation'
    describe 'iiif_image_resource' do
      let(:generic_file) { GenericFile.new(id: 'testa') }
      subject { generic_file.iiif_image_resource }

      it { is_expected.to be_an_instance_of(IIIF::Presentation::ImageResource) }

      it 'generates correct image path' do
        expect(subject['@id']).to eq(
          '/image-service/testa/full/full/0/native.jpg')
      end

      it 'generates correct type' do
        expect(subject['@type']).to eq('dcterms:Image')
      end

      it 'generates correct format' do
        expect(subject['format']).to eq('image/jpeg')
      end

      it 'generates correct height' do
        expect(generic_file).to receive(:height).and_return(['20'])
        expect(subject['height']).to eq(20)
      end

      it 'generates correct width' do
        expect(generic_file).to receive(:width).and_return(['50'])
        expect(subject['width']).to eq(50)
      end
    end
  end

  context 'custom metadata' do
    describe "abstract" do
      it "has it" do
        expect(subject.abstract).to eq([])
        subject.abstract = ['abc']
        subject.save(validate: false)
        expect(subject.reload.abstract).to be_truthy
      end
    end

    describe "bibliographic_citation" do
      it "has it" do
        expect(subject.bibliographic_citation).to eq([])
        subject.bibliographic_citation = ['abc']
        subject.save(validate: false)
        expect(subject.reload.bibliographic_citation).to be_truthy
      end
    end

    describe "subject_name" do
      it "has it" do
        expect(subject.subject_name).to eq([])
        subject.subject_name = ['abc']
        subject.save(validate: false)
        expect(subject.reload.subject_name).to be_truthy
      end
    end

    describe "subject_geographic" do
      it "has it" do
        expect(subject.subject_geographic).to eq([])
        subject.subject_geographic = ['abc']
        subject.save(validate: false)
        expect(subject.reload.subject_geographic).to be_truthy
      end
    end

    describe "lcsh" do
      it "has it" do
        expect(subject.lcsh).to eq([])
        subject.lcsh = ['abc']
        subject.save(validate: false)
        expect(subject.reload.lcsh).to be_truthy
      end
    end

    describe "mesh" do
      it "has it" do
        expect(subject.mesh).to eq([])
        subject.mesh = ['abc']
        subject.save(validate: false)
        expect(subject.reload.mesh).to be_truthy
      end
    end

    describe "digital_origin" do
      it "has it" do
        expect(subject.digital_origin).to eq([])
        subject.digital_origin = ['abc']
        subject.save(validate: false)
        expect(subject.reload.digital_origin).to be_truthy
      end
    end

    describe "page_number" do
      it "has it" do
        expect(subject.page_number).to be_nil
        subject.page_number = 22
        subject.save(validate: false)
        expect(subject.reload.page_number).to eq(22)
      end
    end
  end
end
