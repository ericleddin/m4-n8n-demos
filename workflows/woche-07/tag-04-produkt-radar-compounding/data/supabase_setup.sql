-- Voltbox Produkt-Radar: Feedback-Quelle für die Compounding-Demo (W7T4)
-- Kein RLS nötig – wie bei orders/tickets läuft der Zugriff über die n8n-Credential.

create table public.product_feedback (
  id         bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  source     text not null check (source in ('rezension','feature_request','umfrage','support','social')),
  product    text not null,
  feedback   text not null,
  rating     smallint check (rating between 1 and 5)
);

insert into public.product_feedback (source, product, feedback, rating) values
-- Cluster: Akku-Laufzeit / Kapazität unter Erwartung
('rezension',       'Voltbox Mini 300', 'Hält bei Weitem nicht so lange wie angegeben. Nach zwei Jahren nur noch die halbe Kapazität.', 2),
('rezension',       'Voltbox Pro 1000', 'Kapazität in der Praxis deutlich unter den beworbenen Wattstunden, besonders bei Kälte.', 2),
('umfrage',         'Voltbox Go 500',   'Reale Laufzeit beim Camping enttäuschend, reicht keinen ganzen Tag.', 2),
('support',         'Voltbox Mini 300', 'Akku scheint schon nach wenigen Monaten merklich schwächer zu werden.', null),
('social',          'Voltbox Pro 1000', 'Das Werbeversprechen zur Laufzeit hält im Test einfach nicht.', null),
-- Cluster: App / Bluetooth-Verbindung
('rezension',       'Voltbox Pro 1000', 'Die App verliert ständig die Bluetooth-Verbindung, total nervig.', 3),
('support',         'Voltbox Go 500',   'Verbindung zur App bricht alle paar Minuten ab.', null),
('rezension',       'Voltbox Mini 300', 'App findet das Gerät oft gar nicht erst.', 2),
('social',          'Voltbox Pro 1000', 'App-Pairing ist eine Katastrophe, man muss sich dauernd neu verbinden.', null),
-- Cluster: Lüfter zu laut
('rezension',       'Voltbox Pro 1000', 'Beim Laden ist der Lüfter unangenehm laut.', 3),
('umfrage',         'Voltbox Pro 1000', 'Lüftergeräusch stört nachts deutlich.', 3),
('rezension',       'Voltbox Go 500',   'Lüfter springt schon bei kleiner Last laut an.', 3),
-- Cluster: Gewicht / Tragbarkeit
('rezension',       'Voltbox Pro 1000', 'Für "tragbar" ist das Teil ziemlich schwer und unhandlich.', 3),
('umfrage',         'Voltbox Pro 1000', 'Zu schwer zum Tragen auf längeren Touren.', 3),
-- Feature-Requests
('feature_request', 'Voltbox Pro 1000', 'Bitte USB-C mit 100W Power Delivery, damit man Laptops voll laden kann.', null),
('feature_request', 'Voltbox Mini 300', 'Wäre toll, wenn die App den Stromverbrauch als Statistik anzeigt.', null),
('feature_request', 'Voltbox Solar 120','Ein Bundle aus Powerstation und Solarmodul mit Rabatt wäre super.', null),
-- Positives (Sentiment-Range, der Reporter soll Funktionierendes nicht "fixen")
('rezension',       'Voltbox Solar 120','Lädt auch bei bewölktem Himmel erstaunlich gut, sehr zufrieden.', 5),
('rezension',       'Voltbox Mini 300', 'Perfekt klein und leicht für Wochenendtrips, top.', 5),
('rezension',       'Voltbox Go 500',   'Robust und zuverlässig, hat schon zwei Festivals überstanden.', 4);
