# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito_youth and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

require 'spec_helper'

describe Person::AddRequest::Approver::Event do

  let(:person) { Fabricate(Group::BottomLayer::Member.name, group: groups(:bottom_layer_two)).person }
  let(:requester) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_one)).person }

  let(:user) { Fabricate(Group::BottomLayer::Leader.name, group: groups(:bottom_layer_two)).person }

  subject { Person::AddRequest::Approver.for(request, user) }

  context 'Event' do

    let(:group) { groups(:bottom_group_one_one) }
    let(:event) { Fabricate(:event, groups: [group]) }

    let(:request) do
      Person::AddRequest::Event.create!(
        person: person,
        requester: requester,
        body: event,
        role_type: Event::Role::Participant.sti_name)
    end

    it 'resolves correct subclass based on request' do
      is_expected.to be_a(Person::AddRequest::Approver::Event)
    end

    context '#approve' do

      before do
        Fabricate(:event_question, event: event)
        Fabricate(:event_question, event: event)
        event.reload
      end

      # load before to get correct change counts
      before { subject }

      it 'creates a new participation' do
        expect do
          subject.approve
        end.to change { Event::Participation.count }.by(1)

        p = person.event_participations.first
        expect(p).to be_active
        expect(p.state).to be_nil
        expect(p.roles.count).to eq(1)
        expect(p.roles.first).to be_a(Event::Role::Participant)
        expect(p.answers.count).to eq(2)
        expect(p.application).to be_nil
      end

    end
  end

  context 'Course' do
    let(:group) { groups(:bottom_layer_one) }
    let(:event) { Fabricate(:course, groups: [group]) }

    let(:request) do
      Person::AddRequest::Event.create!(
        person: person,
        requester: requester,
        body: event,
        role_type: role_type.sti_name)
    end

    before do
      Fabricate(:event_question, event: event)
      Fabricate(:event_question, event: event)
      event.reload
    end

    context 'participant' do
      let(:role_type) { Event::Course::Role::Participant }

      it 'creates a new participation' do
        expect do
          subject.approve
        end.to change { Event::Participation.count }.by(1)

        p = person.event_participations.first
        expect(p).to be_active
        expect(p.state).to eq('assigned')
        expect(p.roles.count).to eq(1)
        expect(p.roles.first).to be_a(role_type)
        expect(p.answers.count).to eq(2)
        expect(p.application).to be_present
        expect(p.application.priority_1).to eq event
      end
    end

    context 'leader' do
      let(:role_type) { Event::Role::Leader }

      it 'creates a new participation' do
        expect do
          subject.approve
        end.to change { Event::Participation.count }.by(1)

        p = person.event_participations.first
        expect(p).to be_active
        expect(p.state).to eq('assigned')
        expect(p.roles.count).to eq(1)
        expect(p.roles.first).to be_a(role_type)
        expect(p.answers.count).to eq(2)
        expect(p.application).to be_nil
      end
    end
  end

end
