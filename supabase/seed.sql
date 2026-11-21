-- ~8 fabricated Boston-area spots (not exported from spot-check's own
-- database -- that's explicitly out of scope). Ownerless (owner_id null,
-- which is allowed) since no auth test users are created here. Two are
-- private, to exercise RLS's visibility rule and the Bookmarks screen's
-- "your private spots" filter.

insert into public.spots
  (name, city, spot_type, description, features, difficulty, is_skateable, is_public, rating, lat, lng, status)
values
  ('Eggs', 'Boston', 'street', 'Ledges by the water',
    array['ledge', 'stairs']::public.feature[], 'intermediate', true, true, 5, 42.3554, -71.0656, 'active'),

  ('AQ', 'Boston', 'street', 'Marble ledges downtown',
    array['ledge', 'plaza']::public.feature[], 'intermediate', true, false, 0, 42.3600, -71.0530, 'active'),

  ('Copley Library', 'Boston', 'street', 'Awesome flatground and three stairs',
    array['stairs', 'plaza']::public.feature[], 'intermediate', true, true, 4, 42.3493, -71.0767, 'active'),

  ('Lynch Family Skatepark', 'Cambridge', 'park', 'Boston''s all concrete skatepark',
    array['skatepark']::public.feature[], 'advanced', true, true, 5, 42.3730, -71.0760, 'active'),

  ('Harvard Steps', 'Cambridge', 'street', 'Classic gap-to-rail set, security kicks out fast',
    array['rail', 'stairs']::public.feature[], 'advanced', true, false, 0, 42.3770, -71.1167, 'active'),

  ('Christian Science Plaza', 'Boston', 'street', 'Smooth plaza ground, mellow ledges',
    array['plaza', 'ledge']::public.feature[], 'beginner', true, true, 4, 42.3430, -71.0870, 'active'),

  ('Somerville DIY', 'Somerville', 'diy', 'Volunteer-built quarter pipes and a rail',
    array['rail', 'skatepark']::public.feature[], 'pro', true, true, 3, 42.3876, -71.0995, 'pending'),

  ('South Boston Bowl', 'Boston', 'park', 'Beginner-friendly bowl near the water',
    array['skatepark']::public.feature[], 'beginner', true, true, 4, 42.3380, -71.0452, 'active');
