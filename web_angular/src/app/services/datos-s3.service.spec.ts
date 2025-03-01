import { TestBed } from '@angular/core/testing';

import { DatosS3Service } from './datos-s3.service';

describe('DatosS3Service', () => {
  let service: DatosS3Service;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(DatosS3Service);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
