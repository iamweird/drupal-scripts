#!/usr/bin/env drush

<?php
$result = db_query("SELECT n.nid, n.title FROM {node} n WHERE language = 'und'");
foreach ($result as $record) {
  print "Loaded: {$record->title} [{$record->nid}]\n";
  $node = node_load($record->nid);
  $node->language = 'ru';
  node_save($node);
}
